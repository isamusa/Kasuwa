import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: Text(
            'Messages',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Promotions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Orders Tab
            ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: 5, // Replace with dynamic order message count
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage(
                          'assets/images/seller${index + 1}.jpg'), // Replace with dynamic seller image
                    ),
                    title: Text(
                      'Seller ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Order update message from Seller ${index + 1}.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '12:30 PM', // Replace with dynamic time
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 4),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                              userName: 'Seller ${index + 1}',
                              userImage:
                                  'assets/images/seller${index + 1}.jpg'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Promotions Tab
            ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: 5, // Replace with dynamic promotions count
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(Icons.campaign, color: Colors.purple),
                    ),
                    title: Text(
                      'Promotion ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Special offer or update from Kasuwa.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '9:00 AM', // Replace with dynamic time
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 4),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      // Navigate to promotion details
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
