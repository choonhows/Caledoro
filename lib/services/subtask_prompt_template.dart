/// Builds the prompt sent to the AI for subtask generation.
///
/// This is a separate function (not a method) so it can be tested and
/// reviewed independently of the service implementation.
String buildSubtaskPrompt({
  required String taskTitle,
  required String taskDescription,
}) {
  return '''You are a task decomposition assistant. Break down the following task into 3-7 actionable subtasks.

Task: $taskTitle
${taskDescription.isNotEmpty ? 'Description: $taskDescription' : ''}

Return a JSON array of objects, each with a "label" field containing a short, actionable subtask description. Do not include any text outside the JSON array.

If the task is already atomic and cannot be meaningfully broken down, return an empty array: []

Example format:
[
  {"label": "First subtask"},
  {"label": "Second subtask"}
]''';
}
