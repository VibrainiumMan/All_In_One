import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:all_in_one/pages/auth_pages/view_notes_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth fakeAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockUser = MockUser(
      uid: 'test-user-id',
      email: 'test@test.com',
    );
    fakeAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
  });

  Future<DocumentReference> addTestFolder(String folderName) async {
    return await fakeFirestore.collection('folders').add({
      'folderName': folderName,
      'userId': mockUser.uid,
      'createdAt': Timestamp.now(),
    });
  }

  Future<DocumentReference> addTestNote(String title, String content, String folderId) async {
    return await fakeFirestore.collection('notes').add({
      'title': title,
      'content': content,
      'owner': mockUser.email,
      'folderId': folderId,
      'createdAt': Timestamp.now(),
    });
  }

  testWidgets('ViewNotesPage shows empty state when no folders exist',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: ViewNotesPage(
            firestore: fakeFirestore,
            auth: fakeAuth,
          ),
        ));

        await tester.pumpAndSettle();
        expect(find.text('No folders available.'), findsOneWidget);
      });

  testWidgets('ViewNotesPage can create new folder', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ViewNotesPage(
        firestore: fakeFirestore,
        auth: fakeAuth,
      ),
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pumpAndSettle();

    expect(find.text('Create Folder'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Test Folder');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final folders = await fakeFirestore
        .collection('folders')
        .where('userId', isEqualTo: mockUser.uid)
        .get();

    expect(folders.docs.length, 1);
    expect(folders.docs.first.get('folderName'), 'Test Folder');
  });

  testWidgets('ViewNotesPage can move note to folder', (WidgetTester tester) async {
    // Create test data
    final sourceFolder = await addTestFolder('Source Folder');
    final targetFolder = await addTestFolder('Target Folder');

    // Create a test note with valid Notus document content
    final testNote = await addTestNote(
        'Test Note',
        '[{"insert":"Test Content\\n"}]',  // Valid Notus document content
        sourceFolder.id
    );

    await tester.pumpWidget(MaterialApp(
      home: ViewNotesPage(
        firestore: fakeFirestore,
        auth: fakeAuth,
      ),
    ));

    await tester.pumpAndSettle();

    // First, find and tap the source folder
    await tester.tap(find.byWidgetPredicate(
            (widget) => widget is Text &&
            widget.data == 'Source Folder' &&
            widget.style?.color == Colors.white
    ));
    await tester.pumpAndSettle();

    // Find and tap the move icon (green add icon) in the note card
    final moveIcon = find.byWidgetPredicate(
            (widget) => widget is Icon &&
            widget.icon == Icons.add &&
            widget.color == Colors.green
    );
    await tester.tap(moveIcon.first);
    await tester.pumpAndSettle();

    // In the move dialog, find and tap the target folder ListTile
    final targetFolderTile = find.byWidgetPredicate(
            (widget) => widget is ListTile &&
            widget.title is Text &&
            (widget.title as Text).data == 'Target Folder'
    );
    await tester.tap(targetFolderTile);
    await tester.pumpAndSettle();

    // Verify note was moved
    final movedNote = await fakeFirestore
        .collection('notes')
        .doc(testNote.id)
        .get();
    expect(movedNote.get('folderId'), targetFolder.id);
  });

  testWidgets('ViewNotesPage can rename folder', (WidgetTester tester) async {
    await addTestFolder('Original Name');

    await tester.pumpWidget(MaterialApp(
      home: ViewNotesPage(
        firestore: fakeFirestore,
        auth: fakeAuth,
      ),
    ));

    await tester.pumpAndSettle();

    final editIcon = find.byWidgetPredicate(
            (widget) => widget is Icon &&
            widget.icon == Icons.edit &&
            widget.color == Colors.white
    );
    await tester.tap(editIcon.first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New Name');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    final folders = await fakeFirestore.collection('folders').get();
    expect(folders.docs.first.get('folderName'), 'New Name');
  });

  testWidgets('ViewNotesPage can delete folder', (WidgetTester tester) async {
    final folder = await addTestFolder('Folder to Delete');

    await tester.pumpWidget(MaterialApp(
      home: ViewNotesPage(
        firestore: fakeFirestore,
        auth: fakeAuth,
      ),
    ));

    await tester.pumpAndSettle();

    final deleteIcon = find.byWidgetPredicate(
            (widget) => widget is Icon &&
            widget.icon == Icons.delete &&
            widget.color == Colors.red
    );
    await tester.tap(deleteIcon.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final deletedFolder = await fakeFirestore
        .collection('folders')
        .doc(folder.id)
        .get();
    expect(deletedFolder.exists, false);
  });
}