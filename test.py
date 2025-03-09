from calendar import c
import getpass
import os
from dotenv import load_dotenv, find_dotenv
from utils import llm

from typing import Annotated
from typing_extensions import TypedDict

from langgraph.graph import StateGraph, MessagesState, START


model=llm

def call_model(state: MessagesState):
    response = model.invoke(state["messages"])
    return {"messages": response}


builder = StateGraph(MessagesState)
builder.add_node("call_model", call_model)
builder.add_edge(START, "call_model")

from langgraph.checkpoint.memory import MemorySaver
memory = MemorySaver()


graph = builder.compile(checkpointer=memory)


config = {"configurable": {"thread_id": "1"}}

input_message = {"role": "user", "content": "hi! I'm bob"}
for chunk in graph.stream({"messages": [input_message]}, config=config, stream_mode="values"):
    chunk["messages"][-1].pretty_print()

input_message = {"role": "user", "content": "what's my name?"}
for chunk in graph.stream({"messages": [input_message]}, config=config, stream_mode="values"):
    chunk["messages"][-1].pretty_print()
