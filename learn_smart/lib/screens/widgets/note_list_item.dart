import 'package:flutter/material.dart';
import 'package:learn_smart/models/note.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final bool isTeacher;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(int) onSelect;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget Function()? popupMenuBuilder;

  const NoteListItem({
    Key? key,
    required this.note,
    required this.isTeacher,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelect,
    required this.onTap,
    this.onLongPress,
    this.popupMenuBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4.0,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.note, color: Colors.white),
        ),
        title: Text(
          note.title,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        trailing: isTeacher
            ? isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) => onSelect(note.id),
                    activeColor: Colors.blue,
                  )
                : popupMenuBuilder?.call()
            : null,
        onTap: onTap,
        onLongPress: onLongPress,
        selected: isSelected,
        selectedTileColor: Colors.blue.withOpacity(0.1),
      ),
    );
  }
}
