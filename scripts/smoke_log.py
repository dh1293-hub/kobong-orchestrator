from infra.logging.json_logger import JsonLogger
jl = JsonLogger(env="dev")
jl.log(message="smoke ok (info)")
jl.log(level="ERROR", message="smoke error occurred", err={"type":"ValueError","msg":"bad value","stack":"trace..."})
print("SMOKE_OK")
