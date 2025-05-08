import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, blog_id } = await req.json();

    if (!user_id || !blog_id) {
      return new Response(
        JSON.stringify({
          message: "User ID and Blog ID are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: blogData, error: fetchError } = await supabase
      .from("blogs")
      .select("author")
      .eq("id", blog_id);

    if (fetchError) {
      console.error("Error fetching blog data:", fetchError);
      throw fetchError;
    }

    if (!blogData || blogData.length === 0) {
      return new Response(
        JSON.stringify({
          message: "Blog post not found",
        }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    if (blogData[0].author !== user_id) {
      return new Response(
        JSON.stringify({
          message: "Unauthorized to delete this blog post",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { error: likeError } = await supabase
      .from("likes")
      .delete()
      .eq("post_id", blog_id);

    if (likeError) {
      return new Response(
        JSON.stringify({
          message: "Failed to delete likes",
          error: likeError.message,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data, error } = await supabase
      .from("blogs")
      .delete()
      .eq("id", blog_id);

    if (error) {
      console.error("Error deleting blog post:", error);
      throw error;
    }

    return new Response(
      JSON.stringify({
        message: "Blog post deleted successfully",
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to delete blog post",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
