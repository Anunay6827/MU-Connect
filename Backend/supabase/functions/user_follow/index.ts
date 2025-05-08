import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, other_user_id, type } = await req.json();

    if (!user_id || !other_user_id || typeof type !== "number") {
      return new Response(
        JSON.stringify({ message: "user_id, other_user_id, and type are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    if (type === 0) {
      const { data: existingFollow, error: fetchError } = await supabase
        .from("follows")
        .select("*")
        .eq("follower_id", user_id)
        .eq("following_id", other_user_id)
        .maybeSingle();

      if (fetchError) throw fetchError;

      if (existingFollow) {
        return new Response(
          JSON.stringify({ message: "Already following" }),
          { headers: { "Content-Type": "application/json" } }
        );
      }

      const { error: insertError } = await supabase
        .from("follows")
        .insert({ follower_id: user_id, following_id: other_user_id });

      if (insertError) throw insertError;

      return new Response(
        JSON.stringify({ message: "Followed successfully" }),
        { headers: { "Content-Type": "application/json" } }
      );
    } else {
      const { error: deleteError } = await supabase
        .from("follows")
        .delete()
        .eq("follower_id", user_id)
        .eq("following_id", other_user_id);

      if (deleteError) throw deleteError;

      return new Response(
        JSON.stringify({ message: "Unfollowed successfully" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to process follow/unfollow",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
