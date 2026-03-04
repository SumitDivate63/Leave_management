import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contacts List',
      home: const ContactPage(),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Rahul'),
            subtitle: Text('9876543210'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Sneha'),
            subtitle: Text('9123456780'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Amit'),
            subtitle: Text('9988776655'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Priya'),
            subtitle: Text('9090909090'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Kiran'),
            subtitle: Text('9012345678'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Neha'),
            subtitle: Text('9345678901'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Rohit'),
            subtitle: Text('9765432109'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Anjali'),
            subtitle: Text('9988007766'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Vikram'),
            subtitle: Text('9871234560'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Meera'),
            subtitle: Text('9123987654'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Arjun'),
            subtitle: Text('9001122334'),
            trailing: Icon(Icons.call),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Pooja'),
            subtitle: Text('9887766554'),
            trailing: Icon(Icons.call),
          ),
        ],
      ),
    );
  }
}
