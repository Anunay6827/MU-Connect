import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";
import { uploadImage } from "../main/upload_image.ts";
import { createNotification } from "../main/notification_create.ts";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const formData = await req.formData();

    const author = formData.get("author") as string;
    const content = formData.get("content") as string;
    const imageFile = formData.get("image") as File;

    if (!author || content === undefined) {
      console.log("Missing required fields: author or content");
      return new Response(
        JSON.stringify({ message: "Author and content are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    let imageUrl: string | null = null;

    if (imageFile && imageFile instanceof File) {
      console.log("Image file detected, uploading...");
      imageUrl = await uploadImage(imageFile);

      if (!imageUrl) {
        console.log("Failed to upload image");
        return new Response(
          JSON.stringify({ message: "Failed to upload image" }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }

      console.log("Image uploaded successfully, URL:", imageUrl);
    } else {
      console.log("No image file provided");
    }

    const { data, error } = await supabase
      .from("blogs")
      .insert([
        {
          author: Number(author),
          content,
          image: imageUrl,
        },
      ])
      .select("*");

    if (error) {
      console.error("Supabase insert error:", error);
      throw error;
    }

    const { data: authorData, error: authorError } = await supabase
      .from("users")
      .select("name")
      .eq("id", author)
      .single();

    const authorName = authorData?.name ?? "Someone";

    const { data: followers, error: followerError } = await supabase
      .from("follows")
      .select("follower_id")
      .eq("following_id", author);

    if (followerError) {
      console.error("Failed to fetch followers:", followerError);
    } else if (followers) {
      const message = `${authorName} created a post`;

      for (const follower of followers) {
        try {
          await createNotification(message, follower.follower_id);
        } catch (notifyErr) {
          console.error(
            `Failed to notify user ${follower.follower_id}:`,
            notifyErr
          );
        }
      }
    }

    return new Response(
      JSON.stringify({
        message: "Blog post created successfully",
        blog: data[0],
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to create blog post",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
