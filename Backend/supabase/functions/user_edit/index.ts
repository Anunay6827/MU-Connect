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
    const password = formData.get("password") as string;
    const bio = formData.get("bio") as string;
    const profile_picture = formData.get("profile_picture") as File;

    if (!user_id) {
      return new Response(
        JSON.stringify({
          message: "User ID is required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const updateFields: any = {};

    if (name !== undefined && name !== null && name.trim() !== "") {
      updateFields.name = name;
    }
    
    if (password !== undefined && password !== null && password.trim() !== "") {
      updateFields.password = password;
    }
    
    if (bio !== undefined && bio !== null && bio.trim() !== "") {
      updateFields.bio = bio;
    }

    if (profile_picture && profile_picture instanceof File) {
      const uploadedUrl = await uploadImage(profile_picture);
      if (uploadedUrl) {
        updateFields.profile_picture = uploadedUrl;
      } else {
        return new Response(
          JSON.stringify({
            message: "Failed to upload profile picture",
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
      .from("users")
      .update(updateFields)
      .eq("id", user_id)
      .select("*");

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) {
      return new Response(
        JSON.stringify({
          message: "User not found",
        }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        message: "User details updated successfully",
        user: data[0],
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to update user details",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
