import 'package:connectivity/connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../utils/student.dart';

class Util {

  Connectivity connectivity;
  SharedPreferences prefs;

  final String _loginUrl = 'http://jatinparate.pythonanywhere.com/api/login/';
  final String _uploadUrl = 'http://jatinparate.pythonanywhere.com/api/upload/';
  final String _recogniseUrl = 'http://jatinparate.pythonanywhere.com/api/recognize/';
  final String _getStudentsUrl = 'http://jatinparate.pythonanywhere.com/api/getStudentsList/';
  final String _getAvgAttUrl = 'http://jatinparate.pythonanywhere.com/api/get_average_attendance/';
  final String _sendEmailUrl = 'http://jatinparate.pythonanywhere.com/api/sendEmail/';
  final String _makeAttendanceUrl = 'http://jatinparate.pythonanywhere.com/api/make_attendance/';

  Future<String> makeAttendance(String branch, String klass, String sem, String lec, List students) async{
    if(await isConnected()){
      try{
        var body = json.encode({
          "class" : branch,
          "division" : klass,
          "sem" : sem,
          "lacture_no" : lec,
          "students" : students
        });
        var response = await http.post(_makeAttendanceUrl, body: body, headers: {'Content-type': 'application/json'});
        var data = jsonDecode(response.body);
        if(data['is_successful']){
          return 'true';
        }else{
          return 'false';
        }
      }catch(e){
        return 'error';
      }
    }else{
      return 'noConnection';
    }
  }
  Future<String> sendEmail(String enroll,String branch,String classStr,int total,int present) async {
    if(await isConnected()){
      try{
        var response = await http.post(_sendEmailUrl,body: {
          'enrollment' : enroll,
          'branch' : branch,
          'class_str' : classStr,
          'total_lactures' : total.toString(),
          'present_lactures' : present.toString()
        });
        var data = jsonDecode(response.body);
        if(data.length > 0 && data['msg'] == 'sent'){
          return 'true';
        }else{
          return 'false';
        }
      }catch(e){
        return 'error';
      }
    }else{
      return 'noConnection';
    }
  }

  Future<List> getAvgAttendance(String classStr,String branch,String sem,String enrollNumber) async {
    List values = [];
    if(await isConnected()){
      try{
        var response = await http.post(_getAvgAttUrl,body: {
          'class_str' : classStr,
          'branch' : branch,
          'sem' : 'sem-$sem',
          'enrollment' : enrollNumber
        });
        var data = jsonDecode(response.body);
        if(data.length > 0){
          values.add((data['present']/data['total']*100).toString());
          values.add(data['present']);
          values.add(data['total']);
          return values;
        }else{
          values.add('noData');
          return values;
        }
      }catch(e){
        print(e);
        values.add('error');
        return values;
      }
    }else{
      values.add('noConnection');
      return values;
    }
  }
  Future<List<Student>> getStudentsList(String classStr,String branch,String sem) async {
    final List<Student> students = [];
    if(await isConnected()){
      try{
        var response = await http.post(_getStudentsUrl, body: {
          'branch' : branch,
          'class' : classStr,
          'sem' : sem,
        });
        var studentData = jsonDecode(response.body);
        var _arrStudents = studentData['data'];
        if(_arrStudents.length > 0){
          for(var s in _arrStudents){
            students.add(Student(s['class'],s['branch'],s['enrollment_no'],s['name'],false,s['sem'],s['parent_email']));
          }
        }else{
          students.add(Student('No Students','','','',false,'',''));
        }
        return students;
      }catch(e){
        print(e);
        students.add(Student('Error','','','',false,'',''));
        return students;
      }
    }else{
      students.add(Student('Not Connected','','','',false,'',''));
      return students;
    }
  }
  Future<List<Student>> recogniseStudents(String classStr,String branch,String sem) async {
    final List<Student> students = [];
    if(await isConnected()){
      try{
        var response = await http.post(_recogniseUrl, body: {
         'class_str' : classStr,
          'branch' : branch,
          'sem' : sem,
        });
        var studentData = jsonDecode(response.body);
        String _klass = studentData['class'];
        String _branch = studentData['branch'];
        var _arrStudents = studentData['students'];
        if(_arrStudents.length > 0){
          for(var s in _arrStudents){
            students.add(Student(_klass,_branch,s['enrollment_no'],s['name'],s['is_present'],sem,'parent_email'));
          }
        }else{
          students.add(Student('No Face','','','',false,'',''));
        }
        return students;
      }catch(e){
        print(e);
        students.add(Student('Error','','','',false,'',''));
        return students;
      }
    }else{
      students.add(Student('Not Connected','','','',false,'',''));
      return students;
    }
  }
  Future<String> uploadImages(List<File> images, String branch, String classStr) async {
    if(await isConnected()){
      try{
        Uri uri = Uri.parse(_uploadUrl);
        http.MultipartRequest request = http.MultipartRequest('POST',uri);
        request.fields['property_id'] = '1';
        request.fields['branch'] = branch;
        request.fields['class_str'] = classStr;
        for(int i=0; i<images.length; i++){
          request.files.add(http.MultipartFile('image',http.ByteStream(images[i].openRead()),
              await images[i].length(),filename: images[i].path));
        }
        var streamedResponse = await request.send();
//        streamedResponse.stream.transform(utf8.decoder).listen((value){});
        if(streamedResponse.statusCode == 200){
          return 'true';
        }else{
          return 'false';
        }
      }catch(e){
        print(e);
        return 'error';
      }
    }else{
      return 'noConnection';
    }
  }
  Future<String> validateUser(String email,String password) async {

    if (await isConnected()) {
      try {
        var response = await http.post(_loginUrl,
            body: {'email': '$email', 'password': '$password'});
        var data = jsonDecode(response.body);
        if (data['is_logged_in']) {
          await _setPrefrences(true, data);
          return 'true';
        } else {
          await _setPrefrences(false, data);
          return 'false';
        }
      } catch (e) {
        print(e);
        return 'error';
      }
    } else {
      return 'noConnection';
    }
  }
  _setPrefrences(value,data) async {
    prefs = await SharedPreferences.getInstance();
    if(value){
       prefs.setBool('is_logged_in', true);
       prefs.setString('login_name', data['name']);
       prefs.setString('login_email', data['email']);
    }else{
       prefs.setBool('is_logged_in', false);
    }
  }
  Future<bool> checkLogin() async {
    prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey('is_logged_in')){
      return prefs.getBool('is_logged_in');
    }else{
      prefs.setBool('is_logged_in', false);
      return false;
    }
  }
  Future<List<String>> getNameAndEmail() async {
    prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey('login_name') && prefs.containsKey('login_email')){
      return [prefs.getString('login_name'),prefs.getString('login_email')];
    }else{
      return ['UserName','UserEmail'];
    }
  }
  Future<bool> isConnected() async {
    connectivity = Connectivity();
    Future<ConnectivityResult> futureStatus = connectivity.checkConnectivity();
    ConnectivityResult status = await futureStatus;
    if(status == ConnectivityResult.mobile || status == ConnectivityResult.wifi){
      return true;
    }else{
      return false;
    }
  }
}