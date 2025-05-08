import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, profile_id } = await req.json();

    if (!user_id) {
      return new Response(JSON.stringify({ message: "user_id is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    let query = supabase
      .from("blogs")
      .select(
        `
        id,
        created_at,
        content,
        image,
        author,
        users:author(*),
        likes(post_id, liked_by)
      `
      )
      .order("created_at", { ascending: false });

    if (profile_id) {
      query = query.eq("author", profile_id);
    }

    const { data, error } = await query;

    if (error) throw error;

    const blogs = await Promise.all(
      data.map(async (blog: any) => {
        const is_like =
          blog.likes?.some((like: any) => like.liked_by === user_id) || false;
        const is_author = blog.author === user_id;

        const { count: likes_count, error: countError } = await supabase
          .from("likes")
          .select("id", { count: "exact", head: true })
          .eq("post_id", blog.id);

        if (countError) {
          throw countError;
        }

        return {
          id: blog.id,
          created_at: blog.created_at,
          content: blog.content,
          image: blog.image,
          author: blog.author,
          user: blog.users,
          is_like,
          is_author,
          likes_count: likes_count ?? 0,
        };
      })
    );

    return new Response(JSON.stringify({ blogs }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";
    return new Response(
      JSON.stringify({
        message: "Failed to fetch blogs",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
