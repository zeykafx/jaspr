import 'dart:io';

import 'package:mason/mason.dart' hide Level;

import '../bundles/new_component/new_component_bundle.dart';
import '../logging.dart';
import 'base_command.dart';

class NewCommand extends BaseCommand {
  NewCommand({super.logger}) {
    addSubcommand(ComponentCommand(logger: logger));
  }

  @override
  String get invocation {
    return 'jaspr new <subcommand> [arguments]';
  }

  @override
  String get description => 'Create a new Jaspr component.';

  @override
  String get name => 'new';

  @override
  String get category => 'Project';

  @override
  Future<int> runCommand() async {
    // if no subcommand is provided, show usage
    usageException('Please specify a subcommand.');
  }
}

class ComponentCommand extends BaseCommand {
  ComponentCommand({super.logger}) {
    argParser.addOption(
      'path',
      abbr: 'p',
      defaultsTo: '.',
      help: 'Location where the new component will be created',
    );
    argParser.addSeparator('Component flags: choose which type of component to create (Only use one of these 3 flags)');
    argParser.addFlag(
      'stateless',
      help: 'Create a new stateless component.',
      negatable: false,
      defaultsTo: false,
    );
    argParser.addFlag(
      'stateful',
      help: 'Create a new stateful component.',
      negatable: false,
      defaultsTo: false,
    );
    argParser.addFlag(
      'async',
      help: 'Create a new AsyncStatelessComponent.',
      negatable: false,
      defaultsTo: false,
    );
    argParser.addSeparator('Additional options for the created component');
    argParser.addFlag(
      'client',
      help: 'Create a client component (Only for stateless or stateful components).',
      negatable: false,
      defaultsTo: false,
    );
    argParser.addFlag(
      'with-styles',
      help: 'Add a style rules getter in the component (Only supported in server and static modes).',
      negatable: false,
      defaultsTo: false,
    );
  }

  @override
  String get invocation {
    return 'jaspr new component [arguments] <name>';
  }

  @override
  String get description => 'Create a new Jaspr component.';

  @override
  String get name => 'component';

  @override
  Future<int> runCommand() async {
    final (dir, name) = getTargetDirectory();

    final isStateless = argResults!.flag('stateless');
    final isStateful = argResults!.flag('stateful');
    final isAsync = argResults!.flag('async');

    // validate component flag combinations
    final componentFlagCount = [isStateless, isStateful, isAsync].where((f) => f).length;

    if (componentFlagCount > 1) {
      logger.write(
        'Cannot use multiple component type flags together. Please specify only one of: --stateless, --stateful, or --async.',
        tag: Tag.cli,
        level: Level.error,
      );
      return 1;
    }

    // Default to stateless if no flag is specified
    final useStateless = isStateless || (!isStateful && !isAsync);

    final withStyles = argResults!.flag('with-styles');
    final isClient = argResults!.flag('client');

    // don't create a client component if the component is an AsyncStatelessComponent
    final useClient = isAsync && isClient ? false : isClient;

    return await createFromTemplate(
      'new_component',
      dir,
      name,
      useStateless,
      isStateful,
      isAsync,
      withStyles,
      useClient,
    );
  }

  Future<int> createFromTemplate(
    String template,
    Directory dir,
    String name,
    bool isStateless,
    bool isStateful,
    bool isAsync,
    bool withStyles,
    bool isClient,
  ) async {
    final componentType = isAsync ? 'async stateless' : (isStateless ? 'stateless' : 'stateful');
    final progress = logger.logger!.progress(
      'Generating $componentType component "$name"...',
    );
    final generator = await MasonGenerator.fromBundle(newComponentBundle);
    final files = await generator.generate(
      DirectoryGeneratorTarget(dir),
      vars: {
        'name': name,
        'stateless': isStateless,
        'stateful': isStateful,
        'async': isAsync,
        'styles': withStyles,
        'client': isClient,
      },
      logger: logger.logger,
    );
    progress.complete('Generated $componentType component $name: ${files.first.path}');

    return 0;
  }

  (Directory, String) getTargetDirectory() {
    // componentName is the name for the component, it can be written in PascalCase, camelCase, or snake_cake because
    // the mason template transforms the name into snake_case for the filename and in PascalCase for the class name
    final componentName = argResults!.rest.firstOrNull ?? logger.logger!.prompt('Specify a component name:');

    final pathOption = argResults!.option('path')!;
    final directory = Directory(pathOption).absolute;

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    if (componentName.isEmpty) {
      usageException('"$componentName" is not a valid component name.');
    }

    return (directory, componentName);
  }
}
