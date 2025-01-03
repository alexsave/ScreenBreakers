-- Drop existing tables and functions
DROP FUNCTION IF EXISTS update_daily_usage;
DROP FUNCTION IF EXISTS get_leaderboard_data;
DROP TABLE IF EXISTS daily_usage;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS leaderboards;

-- Create leaderboards table
CREATE TABLE leaderboards (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    name TEXT NOT NULL,
    current_leaderboard_id TEXT REFERENCES leaderboards(id)
);

-- Create daily_usage table
CREATE TABLE daily_usage (
    user_id UUID REFERENCES auth.users(id),
    day INTEGER,
    minutes INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, day)
);

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_usage ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can insert their own user data" ON users
FOR INSERT WITH CHECK (auth.uid()::uuid = id);

CREATE POLICY "Users can update their own data" ON users
FOR UPDATE USING (auth.uid()::uuid = id);

CREATE POLICY "Users can read all users" ON users
FOR SELECT USING (true);

-- Leaderboards table policies
CREATE POLICY "Anyone can read leaderboards" ON leaderboards
FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create leaderboards" ON leaderboards
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update leaderboards they belong to" ON leaderboards
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()::uuid
        AND users.current_leaderboard_id = leaderboards.id
    )
);

-- Daily usage table policies
CREATE POLICY "Users can insert/update their own usage data"
ON daily_usage FOR ALL
USING (auth.uid()::uuid = user_id)
WITH CHECK (auth.uid()::uuid = user_id);

CREATE POLICY "Users can read usage data for their leaderboard"
ON daily_usage FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users u1
        JOIN users u2 ON u1.current_leaderboard_id = u2.current_leaderboard_id
        WHERE u1.id = auth.uid()::uuid
        AND u2.id = daily_usage.user_id
    )
);

-- Create update_daily_usage function
CREATE OR REPLACE FUNCTION update_daily_usage(
    p_user_id UUID,
    p_day INTEGER,
    p_minutes INTEGER
) RETURNS void AS $$
BEGIN
    -- If it's the first day of the month, clear previous month's data
    IF p_day = 1 THEN
        DELETE FROM daily_usage 
        WHERE user_id = p_user_id 
        AND day != 1;
    END IF;

    -- Insert or update today's usage
    INSERT INTO daily_usage (user_id, day, minutes)
    VALUES (p_user_id, p_day, p_minutes)
    ON CONFLICT (user_id, day)
    DO UPDATE SET minutes = p_minutes;
END;
$$ LANGUAGE plpgsql;

-- Create get_leaderboard_data function
CREATE OR REPLACE FUNCTION get_leaderboard_data(
    p_leaderboard_id TEXT,
    p_timezone TEXT
) RETURNS TABLE (
    user_id UUID,
    user_name TEXT,
    today_minutes INTEGER,
    leaderboard_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id AS user_id,
        u.name AS user_name,
        COALESCE(du.minutes, 0) AS today_minutes,
        l.name AS leaderboard_name
    FROM users u
    LEFT JOIN daily_usage du ON u.id = du.user_id 
        AND du.day = EXTRACT(DAY FROM NOW() AT TIME ZONE p_timezone)
    LEFT JOIN leaderboards l ON l.id = p_leaderboard_id
    WHERE u.current_leaderboard_id = p_leaderboard_id
    ORDER BY today_minutes DESC;
END;
$$ LANGUAGE plpgsql; 