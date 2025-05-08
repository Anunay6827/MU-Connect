import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { sender_id, message_id } = await req.json();

    if (!sender_id || !message_id) {
      return new Response(
        JSON.stringify({
          message: "sender_id and message_id are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: messageData, error: fetchError } = await supabase
      .from("chats_messages")
      .select("sender_id")
      .eq("id", message_id)
      .single();

    if (fetchError) {
      console.error("Error fetching message:", fetchError);
      return new Response(
        JSON.stringify({
          message: "Error fetching message data",
          error: fetchError.message,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!messageData || messageData.sender_id !== sender_id) {
      return new Response(
        JSON.stringify({
          message: "Unauthorized or message not found",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data, error: deleteError } = await supabase
      .from("chats_messages")
      .delete()
      .eq("id", message_id);

    if (deleteError) {
      return new Response(
        JSON.stringify({
          message: "Failed to delete message",
          error: deleteError.message,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

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
