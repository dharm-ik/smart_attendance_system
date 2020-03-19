import 'package:flutter/material.dart';
import '../../utils/util.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class ManageStudentsPage extends StatefulWidget {
  static final String id = 'ManageStudentsPageID';
  @override
  _ManageStudentsPageState createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  final Util util = Util();
  bool _isLoading = false;

  List<String> _branches = ['CE', 'IT', 'ME', 'EE'];
  String _currentBranch = 'CE';
  String _branch = 'CE';

  List<String> _classes = ['A', 'B', 'C', 'D', 'E', 'F'];
  String _currentClass = 'E';
  String _class = 'E';

  List<String> _sems = ['sem-1', 'sem-2', 'sem-3', 'sem-4', 'sem-5', 'sem-6', 'sem-7', 'sem-8'];
  String _currentSem = 'sem-8';
  String _sem = 'sem-8';

  Widget createDropDown({@required List<String> list,
    @required String initialItem,@required Function onChanged}) {
    return DropdownButton<String>(
      items: list.map((curItem){
        return DropdownMenuItem<String>(
          value: curItem,
          child: Text(curItem),
        );
      }).toList(),
      value: initialItem,
      onChanged: onChanged,
    );
  }
  _stopLoading() async {
    Future.delayed(Duration(seconds: 2),(){
      setState(() {
        _isLoading = false;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Students'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  createDropDown(list: _branches, initialItem: _currentBranch, onChanged: (value){
                    setState(() {
                      _currentBranch = value;
                      print(value);
                    });
                  }),
                  createDropDown(list: _classes, initialItem: _currentClass, onChanged: (value){
                    setState(() {
                      _currentClass = value;
                      print(value);
                    });
                  }),
                  createDropDown(list: _sems, initialItem: _currentSem, onChanged: (value){
                    setState(() {
                      _currentSem = value;
                      print(value);
                    });
                  }),
                  RaisedButton(
                    child: Text('Get Students'),
                    onPressed: (){
                      setState(() {
                        _isLoading = true;
                        _branch = _currentBranch;
                        _class = _currentClass;
                        _sem = _currentSem;
                      });
                      _stopLoading();
                    },
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: ModalProgressHUD(
              inAsyncCall: _isLoading,
              child: Container(
                child: FutureBuilder(
                  future: util.getStudentsList(_class, _branch, _sem),
                  builder: (BuildContext context,AsyncSnapshot snapshot){
                    if(snapshot.hasData){
                        if(snapshot.data[0].klass == 'Error'){
                          return Center(
                            child: Text('Something went wrong !'),
                          );
                        }else if(snapshot.data[0].klass == 'Not Connected'){
                          return Center(
                            child: Text('No Internet Connection'),
                          );
                        }else if(snapshot.data[0].klass == 'No Students'){
                          return Center(
                            child: Text('No Students Available !'),
                          );
                        }else{
                          return ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context,int index){
                              return Card(
                                color: Colors.blueAccent,
                                margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 8,
                                        child: Text('E.NO: ${snapshot.data[index].enrollNumber}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 7,
                                        child: Text(snapshot.data[index].name,
                                          style: TextStyle(
                                              fontSize: 16
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(snapshot.data[index].klass),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                    }else{
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
