import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, chatter_id } = await req.json();

    if (!user_id || !chatter_id) {
      return new Response(
        JSON.stringify({
          message: "user_id and chatter_id are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data, error } = await supabase
      .from("chats_messages")
      .select("*")
      .or(
        `and(sender_id.eq.${user_id}, receiver_id.eq.${chatter_id}),and(sender_id.eq.${chatter_id}, receiver_id.eq.${user_id})`
      )
      .order("created_at", { ascending: true });

    if (error) {
      return new Response(
        JSON.stringify({
          message: "Error fetching chat messages",
          error: error.message,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        message: "Chats retrieved successfully",
        data: data || [],
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to retrieve chats",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
