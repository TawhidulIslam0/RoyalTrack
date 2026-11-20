import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatefulWidget {const SettingsScreen({super.key});@override State<SettingsScreen> createState()=>_SettingsScreenState();}
class _SettingsScreenState extends State<SettingsScreen>{
 late final TextEditingController url=TextEditingController(text:AppSettings.instance.backendUrl);bool testing=false;
 @override void dispose(){url.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.only(bottom:24),children:[
 const AppHeader(subtitle:'App preferences and API setup'),
 AnimatedBuilder(animation:AppSettings.instance,builder:(context,_)=>SwitchListTile(title:const Text('Dark mode'),subtitle:const Text('Use the dark theme'),value:AppSettings.instance.darkMode,onChanged:AppSettings.instance.setDarkMode)),
 Padding(padding:const EdgeInsets.all(16),child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Text('Backend server',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:8),
 TextField(controller:url,decoration:const InputDecoration(labelText:'Backend URL',hintText:'http://10.0.2.2:3000',border:OutlineInputBorder()),keyboardType:TextInputType.url),
 const SizedBox(height:8),Row(children:[Expanded(child:OutlinedButton(onPressed:()=>AppSettings.instance.setBackendUrl(url.text),child:const Text('Save URL'))),const SizedBox(width:8),Expanded(child:FilledButton(onPressed:testing?null:()=>_test(),child:testing?const Text('Testing…'):const Text('Test connection')))]),
 const SizedBox(height:8),const Text('Android emulator: 10.0.2.2 reaches your PC localhost. Physical device: use your computer LAN IP.'),
 ])))),
 Padding(padding:const EdgeInsets.all(16),child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Text('About data',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:8),
 const Text('This app requests live official API data through your configured backend. Third-party analytics are not fabricated. Backend must have a valid API token and correct IP allowlist.'),
 const SizedBox(height:8),const Text('Independent fan-made project. Not affiliated with Supercell or RoyaleAPI.')
 ])))),
 Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:OutlinedButton.icon(onPressed:()=>_clear(),icon:const Icon(Icons.delete_sweep),label:const Text('Clear saved favorites and decks'))),
 ]));
 Future<void> _test()async{setState(()=>testing=true);await AppSettings.instance.setBackendUrl(url.text);try{await ApiService.instance.testConnection();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Connection successful — cards API responded.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Connection failed: $e')));}finally{if(mounted)setState(()=>testing=false);}}
 Future<void> _clear()async{await AppSettings.instance.clearLocal();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Local favorites and saved decks cleared')));}
}
