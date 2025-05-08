import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, blog_id, type } = await req.json();

    if (!user_id || !blog_id || typeof type !== "number") {
      return new Response(
        JSON.stringify({ message: "user_id, blog_id, and type are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    if (type === 0) {
      const { data: existingLike, error: fetchError } = await supabase
        .from("likes")
        .select("id")
        .eq("liked_by", user_id)
        .eq("post_id", blog_id)
        .maybeSingle();

      if (fetchError) throw fetchError;

      if (existingLike) {
        return new Response(
          JSON.stringify({ message: "Like already exists" }),
          { status: 200, headers: { "Content-Type": "application/json" } }
        );
      }

      const { error: insertError } = await supabase.from("likes").insert({
        liked_by: user_id,
        post_id: blog_id,
      });

      if (insertError) throw insertError;

      return new Response(
        JSON.stringify({ message: "Like added successfully" }),
        { status: 201, headers: { "Content-Type": "application/json" } }
      );
    } else {
      const { error: deleteError } = await supabase
        .from("likes")
        .delete()
        .eq("liked_by", user_id)
        .eq("post_id", blog_id);

      if (deleteError) throw deleteError;

      return new Response(
        JSON.stringify({ message: "Like removed successfully" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to process like",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
