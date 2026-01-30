import 'package:jaspr/dom.dart';
{{^async}}import 'package:jaspr/jaspr.dart';{{/async}}{{#async}}import 'package:jaspr/server.dart';{{/async}}

{{#client}}@client{{/client}}{{#stateless}}
class {{name.pascalCase()}} extends StatelessComponent {
  const {{name.pascalCase()}}({super.key});

  @override
  Component build(BuildContext context) {
    return div([]);
  }{{/stateless}}{{#stateful}}
class {{name.pascalCase()}} extends StatefulComponent {
  const {{name.pascalCase()}}({super.key});

  @override
  State<{{name.pascalCase()}}> createState() => _{{name.pascalCase()}}State();
}

class _{{name.pascalCase()}}State extends State<{{name.pascalCase()}}> {
  {{#client}}
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Run client-side initialization logic here
    } else {
      // Run server-side initialization logic here
    }
  }
  {{/client}}
  @override
  Component build(BuildContext context) {
    return div([]);
  }{{/stateful}}{{#async}}

class {{name.pascalCase()}} extends AsyncStatelessComponent {
  const {{name.pascalCase()}}({super.key});

  @override
  Future<Component> build(BuildContext context) async {
    return div([]);
  }{{/async}}{{#styles}}

  @css
  List<StyleRule> get styles => [];{{/styles}}
}
