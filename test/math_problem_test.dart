import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/backend/project/authentication/math_problem_generator.dart';

void main() {
  test('test MathProblem', () {
    const String answer = "hello world";
    const problem = MathProblem(question: "", answer: answer);
    expect(problem.verifyGuess(answer), isTrue);
  });
  test('test MathProblem negative', () {
    const String answer = "hello wrld";
    const problem = MathProblem(question: "", answer: "hello world");
    expect(problem.verifyGuess(answer), isFalse);
  });
  test('mult', () {
    int left = 3;
    int right = 5;
    MathProblem problem = getMultiplicationProblem(
      leftNumber: left,
      rightNumber: right,
    );

    expect(problem.verifyGuess("15"), isTrue);
  });
}
