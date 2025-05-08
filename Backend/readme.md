## Commands to write and push code to Supabase

- `npm install` after downloading code from Github
- Create a new function using `supabase functions new function_name`
- Before deploying code, run `supabase secrets set --env-file ./supabase/.env` to set the configuration to the code
- Deploy functions to server using `supabase functions deploy function_name`