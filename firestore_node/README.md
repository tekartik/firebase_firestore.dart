## Setup

```yaml
  tekartik_firebase_firestore_node:
    git:
      url: git://github.com/tekartik/firebase_firestore.dart
      path: firestore_node
      ref: dart2
    version: '>=0.8.1'
```
## Test setup

 Use dart2 and set env variable
    
    npm install
    
 Update to latest node package
  
     npm install --save @google-cloud/firestore
     npm install -save firebase-admin

     _package.json
     
## Test

    pub run test -p node
    
    # not working with build runner
    pub run build_runner test -- -p node
    pub run test -p node
    pub run test -p node test/firestore_node_test.dart

### Single test

    pub run test -p node test/firestore_node_test.dart

    pub run build_runner test -- -p node .\test\firestore_node_test.dart

    pbr test -- -p node test/storage_node_test.dart
    pbr test -- -p node test/firestore_node_test.dart
    pbr test -- -p node test/admin_node_test.dart