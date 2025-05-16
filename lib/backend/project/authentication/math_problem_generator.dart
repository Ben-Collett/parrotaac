import 'dart:math';

///returns  a MathProblem representing the multiplication of two integers
///[random] is used to generate the two random numbers if and only if [leftNumber] and [rightNumber] aren't passed in, or are null
///if leftNumber or rightNumber is not passed in then it will be randomly generated
///[minFactor] and [maxFactor] are the min and max values that the leftNumber and rightNumber can be, inculsive, unless the leftNumber and rightNumber are manually passed in
MathProblem getMultiplicationProblem({
  int? leftNumber,
  int? rightNumber,
  int minFactor = 4,
  int maxFactor = 9,
  Random? random,
}) {
  Random rand = random ?? Random();
  if (maxFactor <= minFactor) {
    throw ArgumentError("max factor must be  greater then min factor");
  }

  maxFactor = maxFactor - minFactor + 1;
  final int num1 = leftNumber ?? rand.nextInt(maxFactor) + minFactor;
  final int num2 = rightNumber ?? rand.nextInt(maxFactor) + minFactor;

  return MathProblem(
    question: "what is $num1*$num2",
    answer: "${num1 * num2}",
  );
}

class MathProblem {
  final String question;
  final String _answer;
  bool verifyGuess(String guess) {
    return guess.trim() == _answer;
  }

  int get answerLength {
    return _answer.length;
  }

  const MathProblem({required this.question, required String answer})
      : _answer = answer;
}
