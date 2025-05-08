import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { group_id } = await req.json();

    if (!group_id) {
      return new Response(JSON.stringify({ message: "group_id is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: messages, error: messageError } = await supabase
      .from("groups_messages")
      .select("*")
      .eq("group_id", group_id)
      .order("created_at", { ascending: true });

    if (messageError) throw messageError;

    if (!messages || messages.length === 0) {
      return new Response(
        JSON.stringify({ message: "No messages found", messages: [] }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    const senderIds = Array.from(
      new Set(messages.map((msg) => msg.sender).filter(Boolean))
    );

    const { data: users, error: userError } = await supabase
      .from("users")
      .select("id, name, profile_picture")
      .in("id", senderIds);

    if (userError) throw userError;

    const userMap = new Map(users.map((user) => [user.id, user]));

    const enrichedMessages = messages.map((msg) => ({
      ...msg,
      sender_info: userMap.get(msg.sender) || null,
    }));

    return new Response(
      JSON.stringify({
        message: "Messages fetched successfully",
        messages: enrichedMessages,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";
    return new Response(
      JSON.stringify({
        message: "Failed to fetch messages",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});