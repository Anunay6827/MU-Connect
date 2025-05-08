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

    const sender_id_raw = formData.get("sender_id");
    const receiver_id_raw = formData.get("receiver_id");
    const content_raw = formData.get("content");
    const content_type_raw = formData.get("content_type");
    const imageFile = formData.get("image") as File | null;

    const sender_id = Number(sender_id_raw);
    const receiver_id = Number(receiver_id_raw);
    const content_type = Number(content_type_raw);
    const content = typeof content_raw === "string" ? content_raw : "";

    if (isNaN(sender_id) || isNaN(receiver_id) || isNaN(content_type)) {
      return new Response(
        JSON.stringify({
          message:
            "sender_id, receiver_id, and content_type must be valid numbers",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    let finalContent = content;

    if (content_type === 1) {
      if (!imageFile || !(imageFile instanceof File)) {
        return new Response(
          JSON.stringify({ message: "Image is required for content_type 1" }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }

      const imageUrl = await uploadImage(imageFile);
      if (!imageUrl) {
        return new Response(
          JSON.stringify({ message: "Failed to upload image" }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }

      finalContent = imageUrl;
    }

    const { data, error } = await supabase
      .from("chats_messages")
      .insert([
        {
          sender_id,
          receiver_id,
          content: finalContent,
          content_type,
        },
      ])
      .select("*");

    if (error) {
      return new Response(
        JSON.stringify({
          message: "Failed to create message",
          error: error.message,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: senderData, error: senderError } = await supabase
      .from("users")
      .select("name")
      .eq("id", sender_id)
      .single();

    if (senderError || !senderData?.name) {
      console.error("Failed to fetch sender name:", senderError?.message);
    } else {
      const notificationContent = `${senderData.name} sent you a message`;
      try {
        await createNotification(notificationContent, receiver_id);
      } catch (notifyErr) {
        console.error("Failed to create notification:", notifyErr);
      }
    }

    return new Response(
      JSON.stringify({
        message: "Message sent successfully",
        data: data[0],
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to create message",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
