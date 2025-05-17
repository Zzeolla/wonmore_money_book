Dismissible
(
key: ValueKey(todo.id),
direction: DismissDirection.startToEnd,
onDismissed: (_) {
context.read<TodoProvider>().toggleTodo(todo.id, true);
_showFlushBar(context, todo.id, todo.title);
},
background: Container(
padding: const EdgeInsets.symmetric(horizontal: 20),
alignment: Alignment.centerLeft,
decoration: BoxDecoration(
color: Colors.green,
borderRadius: BorderRadius.circular(12),
),
child: const Icon(Icons.check, color: Colors.white),
),
child: Card(
margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
color: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
side: const BorderSide(color: Colors.amberAccent, width: 1),
),
child: InkWell(
onLongPress: () => _confirmDelete(context, todo.id),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: Colors.amberAccent, width: 1),
),
child: Row(
children: [
CircleAvatar(
radius: 14,
backgroundColor: Colors.deepPurple.shade300,
child: const Icon(Icons.checklist, size: 16, color: Colors.white),
),
const SizedBox(width: 12),
Expanded(
child: Text(
todo.title,
style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
),
),
IconButton(
icon: const Icon(Icons.radio_button_unchecked, color: Colors.deepPurpleAccent),
onPressed: () {
context.read<TodoProvider>().toggleTodo(todo.id, true);
_showFlushBar(context, todo.id, todo.title);
},
),
],
),
),
),
)
,
);