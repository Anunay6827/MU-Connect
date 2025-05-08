import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, profile_id } = await req.json();

    if (typeof user_id !== "number" || typeof profile_id !== "number") {
      return new Response(
        JSON.stringify({
          message: "user_id and profile_id are required and must be numbers",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const { data: user, error: userError } = await supabase
      .from("users")
      .select("*")
      .eq("id", profile_id)
      .single();

    if (userError) throw userError;
    if (!user) {
      return new Response(
        JSON.stringify({ message: "Profile user not found" }),
        {
          status: 404,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const { count: postCount, error: postError } = await supabase
      .from("blogs")
      .select("*", { count: "exact", head: true })
      .eq("author", profile_id);

    if (postError) throw postError;

    const { count: followersCount, error: followersError } = await supabase
      .from("follows")
      .select("*", { count: "exact", head: true })
      .eq("following_id", profile_id);

    if (followersError) throw followersError;

    const { count: followingCount, error: followingError } = await supabase
      .from("follows")
      .select("*", { count: "exact", head: true })
      .eq("follower_id", profile_id);

    if (followingError) throw followingError;

    const { data: followCheck, error: followError } = await supabase
      .from("follows")
      .select("id")
      .eq("follower_id", user_id)
      .eq("following_id", profile_id)
      .maybeSingle();

    if (followError) throw followError;
    const is_following = !!followCheck;

    return new Response(
      JSON.stringify({
        message: "Profile fetched successfully",
        user,
        stats: {
          posts: postCount ?? 0,
          followers: followersCount ?? 0,
          following: followingCount ?? 0,
        },
        is_following,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";
    return new Response(
      JSON.stringify({
        message: "Failed to fetch profile",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
