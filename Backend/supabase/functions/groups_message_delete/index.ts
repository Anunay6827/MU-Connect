import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { message_id, user_id, group_id } = await req.json();

    if (!message_id || !user_id || !group_id) {
      return new Response(
        JSON.stringify({
          message: "message_id, user_id, and group_id are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: messageRecords, error: checkError } = await supabase
      .from("groups_messages")
      .select("id")
      .eq("id", message_id)
      .eq("sender", user_id)
      .eq("group_id", group_id);

    if (checkError || !messageRecords || messageRecords.length === 0) {
      return new Response(
        JSON.stringify({
          message: "No matching message found for user in group",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { error: deleteError } = await supabase
      .from("groups_messages")
      .delete()
      .eq("id", message_id);

    if (deleteError) throw deleteError;

    return new Response(
      JSON.stringify({
        message: "Message deleted successfully",
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to delete message",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
