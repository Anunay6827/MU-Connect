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

    const user_id_raw = formData.get("user_id");
    const group_id_raw = formData.get("group_id");
    const content_raw = formData.get("content");
    const content_type_raw = formData.get("content_type");
    const imageFile = formData.get("image") as File | null;

    const user_id = Number(user_id_raw);
    const group_id = Number(group_id_raw);
    const content_type = Number(content_type_raw);
    const content = typeof content_raw === "string" ? content_raw : "";

    if (isNaN(user_id) || isNaN(group_id) || isNaN(content_type)) {
      return new Response(
        JSON.stringify({
          message: "user_id, group_id, and content_type must be valid numbers",
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

    const { data: memberRecords, error: memberCheckError } = await supabase
      .from("group_members")
      .select("id")
      .eq("group_id", group_id)
      .eq("member_id", user_id);

    if (memberCheckError || !memberRecords || memberRecords.length === 0) {
      return new Response(
        JSON.stringify({
          message: "User is not a member of the group",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data, error: insertError } = await supabase
      .from("groups_messages")
      .insert([
        {
          content: finalContent,
          content_type,
          sender: user_id,
          group_id,
        },
      ])
      .select("*");

    if (insertError) throw insertError;

    const { data: senderData, error: senderError } = await supabase
      .from("users")
      .select("name")
      .eq("id", user_id)
      .single();

    const { data: groupData, error: groupError } = await supabase
      .from("groups")
      .select("name")
      .eq("id", group_id)
      .single();

    if (senderData?.name && groupData?.name) {
      const notificationText = `${senderData.name} sent a message in the group ${groupData.name}`;

      const { data: allMembers, error: membersError } = await supabase
        .from("group_members")
        .select("member_id")
        .eq("group_id", group_id);

      if (!membersError && allMembers) {
        const receivers = allMembers
          .map((m) => m.member_id)
          .filter((id) => id !== user_id);
        for (const receiver of receivers) {
          try {
            await createNotification(notificationText, receiver);
          } catch (notifyErr) {
            console.error(`Failed to notify user ${receiver}:`, notifyErr);
          }
        }
      }
    }

    return new Response(
      JSON.stringify({
        message: "Message sent successfully",
        message_record: data[0],
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to send message",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
