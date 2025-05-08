import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, type } = await req.json();

    if (!user_id || typeof type !== "number") {
      return new Response(
        JSON.stringify({ message: "user_id and type are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    let query;
    if (type === 0) {
      query = supabase
        .from("follows")
        .select("id, created_at, following_id, users:following_id(*)")
        .eq("follower_id", user_id);
    } else {
      query = supabase
        .from("follows")
        .select("id, created_at, follower_id, users:follower_id(*)")
        .eq("following_id", user_id);
    }

    const { data, error } = await query;

    if (error) throw error;

    return new Response(JSON.stringify({ follows: data }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";
    return new Response(
      JSON.stringify({
        message: "Failed to fetch follow data",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
