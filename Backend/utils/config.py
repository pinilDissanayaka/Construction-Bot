from dotenv import load_dotenv
from typing_extensions import TypedDict, Annotated
from langgraph.graph.message import add_messages
from langchain_openai.chat_models import ChatOpenAI


load_dotenv()


llm = ChatOpenAI(
    model="gpt-4o-mini",
    temperature=0.7,
)


class State(TypedDict):
    messages: Annotated[list, add_messages]
    name: str


config={"configurable": {"thread_id": "2"}}


