import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { user_id, group_id } = await req.json();

    if (!user_id || !group_id) {
      return new Response(
        JSON.stringify({
          message: "User ID and Group ID are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: groupMemberData, error: memberError } = await supabase
      .from("group_members")
      .select("is_admin")
      .eq("group_id", group_id)
      .eq("member_id", user_id)
      .single();

    if (memberError) {
      throw memberError;
    }

    if (!groupMemberData) {
      return new Response(
        JSON.stringify({
          message: "User is not a member of the group",
        }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    if (groupMemberData.is_admin) {
      return new Response(
        JSON.stringify({
          message: "Admin cannot exit the group",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { error: deleteError } = await supabase
      .from("group_members")
      .delete()
      .eq("group_id", group_id)
      .eq("member_id", user_id);

    if (deleteError) {
      throw deleteError;
    }

    return new Response(
      JSON.stringify({
        message: "User successfully exited the group",
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to exit the group",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
