from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"status": "Trap-PR Agent Backend is running (Cloud Run Ready!)"}