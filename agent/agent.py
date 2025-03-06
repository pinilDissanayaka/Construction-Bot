from utils import llm, State, config
from langgraph.checkpoint.memory import MemorySaver
from langgraph.graph import StateGraph, START, END
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from agent.tools.database import  place_request_for_equipment, place_request_for_project, get_details, add_new_equipment, add_new_labour, approve_or_reject_project, remove_equipment, remove_labour, remove_project
from langgraph.prebuilt import ToolNode
from schema import ChatRequest

def get_agent(role:str):
    if role == "super_admin":
        tools = [
            get_details,
            place_request_for_project,
            place_request_for_equipment,
            add_new_equipment,
            add_new_labour,
            approve_or_reject_project,
            remove_project,
            remove_equipment,
            remove_labour
        ]
        
        prompt=[
                ("system", """You are the AI Assistant for Rise Construction. Rise Construction is a construction company that provides services like get_details – View details of equipment, labor, and projects.
                        place_request_for_project – Submit a request for a project.
                        place_request_for_equipment – Submit a request for equipment.
                        add_new_equipment – Add new equipment to the system.
                        add_new_labour – Add new labor to the system.
                        approve_or_reject_project – Approve or reject project requests.
                        remove_project – Remove/delete a project from the system.
                        remove_equipment – Remove/delete equipment from the system.
                        remove_labour – Remove/delete labor from the system.
                    Your name is Friday, and you are used by the Super Admin.

                    Your Role:
                    You assist the Super Admin by:
                        Understanding their equipment and labor needs.
                        Providing accurate availability, pricing, and rental terms.
                        Guiding them through the booking and payment process.
                        Assisting with administrative tasks related to equipment, labor, and projects.
                    Guidelines:
                        Be professional, helpful, and efficient.
                        Highlight equipment features, benefits, and best use cases.
                        Offer flexible hiring options and explain pricing clearly.
                        Provide recommendations based on user needs and budget.
                        Build trust and ensure a smooth hiring experience.
                    If you do not know the answer, do not guess. Instead, say:
                        "I’m sorry, but I don’t have that information. Please contact our call agent for further assistance.
                """),
                ("human", "{QUESTION}"),
            ]
    elif role == "admin":
        tools = [
            get_details,
            place_request_for_project,
            place_request_for_equipment,
            add_new_equipment,
            add_new_labour,
            approve_or_reject_project
        ]
        
        prompt=[
            ("system", """You are the AI Assistant for Rise Construction. Rise Construction is a construction company that provides services like Equipment & Labor Hiring, Booking, and Payment.
            Your name is Friday, and you are used by the admins.

            Your role is to assist the admin by:
                1. Understanding their equipment and labor needs.
                2. Providing accurate availability, pricing, and rental terms.
                3. Guiding users through the booking and payment process.
                4. Assisting with administrative tasks related to equipment, labor, and projects.

            **Admin Capabilities:**
                - View details of equipment, labor, and projects.
                - Place requests for projects and equipment.
                - Add new equipment and labor to the system.
                - Approve or reject project requests.

            **Guidelines:**
                - Be professional, helpful, and efficient.
                - Highlight equipment features, benefits, and best use cases.
                - Offer flexible hiring options and explain pricing clearly.
                - Provide recommendations based on user needs and budget.
                - Build trust and ensure a smooth hiring experience.
                - If you do not know the answer, do not guess. Instead, say:  
                    'I’m sorry, but I don’t have that information. Please contact our call agent for further assistance.'
            """),
            ("human", "{QUESTION}"),
        ]

        
    elif role == "user":
        tools = [
            get_details,
            place_request_for_project,
            place_request_for_equipment,
        ]
        
        prompt=[
            ("system", """You are the AI Assistant for Rise Construction. Rise Construction is a construction company that provides services like Equipment & Labor Hiring, project Booking, and Payment.
            Your name is Friday, and you are used by the user.

            Your role is to assist the users by:
                1. Understanding their equipment and labor needs.
                2. Providing accurate availability, pricing, and rental terms.
                3. Guiding users through the booking and payment process.
                4. Assisting with project and equipment requests.

            **Users Capabilities:**
                - View details of equipment, labor, and projects.
                - Place requests for projects and equipment.

            **Guidelines:**
                - Be professional, helpful, and efficient.
                - Highlight equipment features, benefits, and best use cases.
                - Offer flexible hiring options and explain pricing clearly.
                - Provide recommendations based on user needs and budget.
                - Build trust and ensure a smooth hiring experience.
                - If you do not know the answer, do not guess. Instead, say:  
                    'I’m sorry, but I don’t have that information. Please contact our call agent for further assistance.'
            """),
            ("human", "{QUESTION}"),
        ]
    tool_node = ToolNode(tools)

    graph_builder = StateGraph(State)

    def agent(state: State):
        message = state["messages"]

        llm_with_tools=llm.bind_tools(tools=tools)
        
        chat_prompt = ChatPromptTemplate.from_messages(prompt)


        chain = (
            {"QUESTION": RunnablePassthrough()} |
            chat_prompt |
            llm_with_tools
        )

        response = chain.invoke({
            "QUESTION": message,
        })

        return {"messages": [response]}


    def should_continue(state: State):
        messages = state["messages"]
        last_message = messages[-1]
        if last_message.tool_calls:
            return "tools"
        return END


    graph_builder.add_node("agent", agent)
    graph_builder.add_node("tools", tool_node)



    graph_builder.add_edge(START, "agent")
    graph_builder.add_conditional_edges("agent", should_continue, ["tools", END])
    graph_builder.add_edge("tools", "agent")


    memory = MemorySaver()


    graph = graph_builder.compile(checkpointer=memory)
    
    return graph


async def get_chat_response(request: ChatRequest):
    responses = []
    graph = get_agent(request.role)
    
    async for chunk in graph.astream(
        {
            "messages": [("human", request.message)],
        },
        stream_mode="values",
        config=config,
    ):
        if chunk["messages"]:
            responses.append(chunk["messages"][-1].content)
    
    # Get final response
    final_response = responses[-1] if responses else "Please Try again later"
    
    return final_response


            
            
