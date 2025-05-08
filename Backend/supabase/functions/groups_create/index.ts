import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";
import { uploadImage } from "../main/upload_image.ts";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const formData = await req.formData();

    const user_id = formData.get("user_id") as string;
    const name = formData.get("name") as string;
    const bio = formData.get("bio") as string | null;
    const picture = formData.get("picture") as File | null;

    if (!user_id || !name) {
      return new Response(
        JSON.stringify({ message: "User ID and group name are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    let uploadedUrl: string | null = null;

    if (picture && picture instanceof File) {
      uploadedUrl = await uploadImage(picture);
      if (!uploadedUrl) {
        return new Response(
          JSON.stringify({ message: "Failed to upload group picture" }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }
    }

    const { data: groupData, error: groupError } = await supabase
      .from("groups")
      .insert([
        {
          name,
          bio: bio || null,
          picture: uploadedUrl || null,
        },
      ])
      .select("id");

    if (groupError) {
      throw groupError;
    }

    const group_id = groupData?.[0].id;

    const { error: memberError } = await supabase.from("group_members").insert([
      {
        group_id,
        member_id: user_id,
        is_admin: true,
      },
    ]);

    if (memberError) {
      throw memberError;
    }

    return new Response(
      JSON.stringify({
        message: "Group created and user added as admin successfully",
        group_id,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to create group",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});