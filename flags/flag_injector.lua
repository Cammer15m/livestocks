-- flag_injector.lua
-- Injects flags into Redis for each lab

local flags = {
  "flag:01",  -- Lab 1
  "flag:02",  -- Lab 2
  "flag:03"   -- Lab 3
}
local values = {
  "RDI{pg_to_redis_success}",
  "RDI{snapshot_vs_cdc_detected}",
  "RDI{advanced_features_mastered}"
}

for i, key in ipairs(flags) do
  redis.call('SET', key, values[i])
end

return #flags
