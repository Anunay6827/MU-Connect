import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { receiver } = await req.json();

    if (!receiver) {
      return new Response(
        JSON.stringify({ message: "Receiver ID is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data, error } = await supabase
      .from("notifications")
      .select("*")
      .eq("receiver", receiver)
      .order("created_at", { ascending: false });

    if (error) {
      throw error;
    }

    return new Response(
      JSON.stringify({
        message: `Notifications for receiver ${receiver} fetched successfully`,
        notifications: data,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to fetch notifications",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
