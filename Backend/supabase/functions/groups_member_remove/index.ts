import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { admin_id, group_id, user_id_to_remove } = await req.json();

    if (!admin_id || !group_id || !user_id_to_remove) {
      return new Response(
        JSON.stringify({
          message: "admin_id, group_id, and user_id_to_remove are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: adminRecords, error: adminError } = await supabase
      .from("group_members")
      .select("is_admin")
      .eq("group_id", group_id)
      .eq("member_id", admin_id);

    if (
      adminError ||
      !adminRecords ||
      adminRecords.length === 0 ||
      !adminRecords[0]?.is_admin
    ) {
      return new Response(
        JSON.stringify({
          message: "Only an admin can remove members from the group",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: memberRecords, error: memberError } = await supabase
      .from("group_members")
      .select("is_admin")
      .eq("group_id", group_id)
      .eq("member_id", user_id_to_remove);

    if (memberError) throw memberError;

    if (
      memberRecords &&
      memberRecords.length > 0 &&
      memberRecords[0]?.is_admin
    ) {
      return new Response(
        JSON.stringify({
          message: "Cannot remove another admin from the group",
        }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    const { error: deleteError } = await supabase
      .from("group_members")
      .delete()
      .eq("group_id", group_id)
      .eq("member_id", user_id_to_remove);

    if (deleteError) throw deleteError;

    return new Response(
      JSON.stringify({
        message: "User removed from group successfully",
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to remove user from group",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});