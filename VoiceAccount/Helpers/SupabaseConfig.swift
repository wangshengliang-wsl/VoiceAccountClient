//
//  SupabaseConfig.swift
//  VoiceAccount
//
//  Configuration for Supabase connection
//

import Foundation

struct SupabaseConfig {
    // IMPORTANT: Replace these values with your actual Supabase project credentials
    // Get these from: https://supabase.com/dashboard/project/_/settings/api

    static let supabaseURL = "https://tzqzducblwsjynbrjlcj.supabase.co" // e.g., "https://xxxxx.supabase.co"

    // ⚠️ IMPORTANT: Use the ANON key (not service_role key) for client-side authentication
    // The ANON key respects Row Level Security policies
    // Get this from: Supabase Dashboard > Project Settings > API > "anon public" key
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6cXpkdWNibHdzanluYnJqbGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxNjE3MDUsImV4cCI6MjA3NzczNzcwNX0.2CVRkD0xSGV_V3E3kcZgG7Q7seWN8Rf4-Y3ONIYupSg" // Replace with your anon/public key

    // Validate configuration
    static var isConfigured: Bool {
        return !supabaseURL.contains("YOUR_") && !supabaseAnonKey.contains("YOUR_")
    }
}

// MARK: - Configuration Instructions
/*

 HOW TO CONFIGURE SUPABASE:

 1. Create a Supabase account at https://supabase.com

 2. Create a new project in Supabase Dashboard

 3. Go to Project Settings > API
    - Copy the "Project URL" and replace YOUR_SUPABASE_URL_HERE
    - Copy the "anon public" key and replace YOUR_SUPABASE_ANON_KEY_HERE

 4. Run the database_setup.sql script in Supabase SQL Editor:
    - Go to SQL Editor in Supabase Dashboard
    - Copy the contents of VoiceAccountServer/database_setup.sql
    - Paste and run the script to create tables and policies

 5. Enable Email Auth in Supabase:
    - Go to Authentication > Providers
    - Enable "Email" provider
    - Configure email templates (optional)

 6. (Optional) Enable Social Auth:
    - Go to Authentication > Providers
    - Enable Apple Sign In or Google Sign In
    - Follow the provider-specific setup instructions

 7. Configure Storage (for audio files):
    - Ensure the "user-audio" bucket exists (created by backend)
    - Or manually create it in Storage section

 SECURITY NOTES:
 - The anon key is safe to use in the client app
 - Row Level Security (RLS) protects user data
 - Never use the service role key in the client app

 */
