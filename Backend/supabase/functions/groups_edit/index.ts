import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";
import { uploadImage } from "../main/upload_image.ts";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const formData = await req.formData();

    const group_id = formData.get("group_id") as string;
    const name = formData.get("name") as string;
    const bio = formData.get("bio") as string;
    const picture = formData.get("picture") as File;

    if (!group_id) {
      return new Response(
        JSON.stringify({
          message: "Group ID is required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const updateFields: any = {};

    if (name !== undefined && name !== null && name.trim() !== "") {
      updateFields.name = name;
    }

    if (bio !== undefined && bio !== null && bio.trim() !== "") {
      updateFields.bio = bio;
    }

    if (picture && picture instanceof File) {
      const uploadedUrl = await uploadImage(picture);
      if (uploadedUrl) {
        updateFields.picture = uploadedUrl;
      } else {
        return new Response(
          JSON.stringify({
            message: "Failed to upload group picture",
          }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }
    }

    if (Object.keys(updateFields).length === 0) {
      return new Response(
        JSON.stringify({
          message: "At least one field to update is required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data, error } = await supabase
      .from("groups")
      .update(updateFields)
      .eq("id", group_id)
      .select("*");

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) {
      return new Response(
        JSON.stringify({
          message: "Group not found",
        }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        message: "Group details updated successfully",
        group: data[0],
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to update group details",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
