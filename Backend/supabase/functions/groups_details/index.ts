import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.3";

const SUP_URL = Deno.env.get("_SUPABASE_URL") as string;
const SUP_KEY = Deno.env.get("_SUPABASE_KEY") as string;
const supabase = createClient(SUP_URL, SUP_KEY);

Deno.serve(async (req) => {
  try {
    const { group_id, user_id } = await req.json();

    if (!group_id || !user_id) {
      return new Response(
        JSON.stringify({
          message: "Group ID and User ID are required",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { data: groupData, error: groupError } = await supabase
      .from("groups")
      .select("*")
      .eq("id", group_id);

    if (groupError) throw groupError;

    if (!groupData || groupData.length === 0) {
      return new Response(
        JSON.stringify({
          message: "Group not found",
        }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    const group = groupData[0];

    const { data: groupMembers, error: membersError } = await supabase
      .from("group_members")
      .select("*")
      .eq("group_id", group_id);

    if (membersError) throw membersError;

    const memberIds = groupMembers.map((member) => member.member_id);

    const { data: usersData, error: usersError } = await supabase
      .from("users")
      .select("*")
      .in("id", memberIds);

    if (usersError) throw usersError;

    const membersWithAdminStatus = usersData.map((user) => {
      const memberRecord = groupMembers.find(
        (member) => member.member_id === user.id
      );
      return {
        ...user,
        is_admin: memberRecord?.is_admin ?? false,
      };
    });

    const { data: userAdminStatus, error: adminError } = await supabase
      .from("group_members")
      .select("is_admin")
      .eq("group_id", group_id)
      .eq("member_id", user_id);

    if (adminError) throw adminError;

    const isAdmin =
      userAdminStatus && userAdminStatus.length > 0
        ? userAdminStatus[0].is_admin
        : false;

    return new Response(
      JSON.stringify({
        message: "Group details and members fetched successfully",
        group: group,
        members: membersWithAdminStatus,
        user_is_admin: isAdmin,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";

    return new Response(
      JSON.stringify({
        message: "Failed to fetch group details and members",
        error: errorMessage,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
