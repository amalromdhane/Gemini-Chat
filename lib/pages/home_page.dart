import 'dart:async';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';


class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();

}

class _MyHomePageState extends State<HomePage> {
  
final Gemini gemini= Gemini.instance;

List<ChatMessage> messages=[];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini" , profileImage:
"https://seeklogo.com/images/G/google-gemini-logo_A5787B2669-seeklogo.com.png",

);

StreamSubscription? _geminiSubscription;

  @override
  
    Widget build(BuildContext){
      return Scaffold(
        appBar:AppBar(
        centerTitle:true,
        title: const Text(
          "Gemini Chat",
        ),
),
body: _buildUI(),



      );
    }

    Widget _buildUI(){
      return DashChat(currentUser : currentUser, onSend: _sendMessage, messages: messages);
    }


  void _sendMessage(ChatMessage chatMessage) async {
  setState(() {
    messages = [chatMessage, ...messages]; // Add the user's message
  });

  // Cancel any active subscription before starting a new one
  _geminiSubscription?.cancel();

  try {
    String question = chatMessage.text;

    // Start a new stream for content generation
    _geminiSubscription = gemini.streamGenerateContent(question).listen((event) {
      // Ensure you're accessing the event safely
      if (event.content != null && event.content?.parts != null) {
        ChatMessage? lastMessage = messages.firstOrNull;

        // Safely combine parts or provide a default empty string if parts are null
        String response = event.content!.parts!.isNotEmpty 
          ? event.content!.parts!.fold("", (previous, current) => "$previous${current.text}") 
          : ""; // Or handle the case as needed

        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0); // Remove the old Gemini response
          lastMessage.text = response; // Update the message text

          setState(() {
            messages = [lastMessage!, ...messages]; // Update the messages list
          });
        } else {
          ChatMessage message = ChatMessage(
            user: geminiUser,
            text: response,
            createdAt: DateTime.now(),
          );

          setState(() {
            messages = [message, ...messages]; // Add the new Gemini response
          });
        }
      } else {
        print("Received content is null or parts are null."); // Log if the content is null
      }
    }, onError: (error) {
      print("Stream Error: $error"); // Handle any stream errors
    });
  } catch (e) {
    print("Error: $e"); // Handle any other errors
  }
}

}