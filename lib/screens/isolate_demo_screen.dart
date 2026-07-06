import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isolate_demo/data/data_impl/isolate_spawn_impl.dart';
import 'package:isolate_demo/data/source/calculate_prime.dart';
import 'package:isolate_demo/screens/widgets/isolate_demo_card.dart';

class IsolateDemoScreen extends StatefulWidget {
  const IsolateDemoScreen({super.key});

  @override
  State<IsolateDemoScreen> createState() => _IsolateDemoScreenState();
}

class _IsolateDemoScreenState extends State<IsolateDemoScreen> {
  List<int> _primeList = [];
  bool _isLoading = false;
  String _currentMethod = "None";
  Duration _executionTime = Duration.zero;

  Future<void> _measurePerformance(
    String method,
    Future<List<int>> Function() computation,
  ) async {
    setState(() {
      _isLoading = true;
      _currentMethod = method;
      _primeList.clear();
    });

    final stopwatch = Stopwatch()..start();
    final results = await computation();
    stopwatch.stop();

    setState(() {
      _primeList = results;
      _executionTime = stopwatch.elapsed;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: const Text(
          "Isolate Performance Lab",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusHeader(theme),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                          ),
                      delegate: SliverChildListDelegate([
                        IsolateDemoCard(
                          title: "Blocking UI",
                          subtitle: "Runs directly on Main Thread",
                          buttonTitle: "Sync Run",
                          icon: Icons.block,
                          color: Colors.redAccent,
                          isLoading: _isLoading && _currentMethod == "Sync",
                          onClick:
                              () => _measurePerformance("Sync", () async {
                                return CalculatePrime.calculatePrimeNum(
                                  5000000,
                                );
                              }),
                        ),
                        IsolateDemoCard(
                          title: "Standard Future",
                          subtitle: "Async but still Event Loop",
                          buttonTitle: "Future Run",
                          icon: Icons.hourglass_empty,
                          color: Colors.orangeAccent,
                          isLoading: _isLoading && _currentMethod == "Future",
                          onClick:
                              () => _measurePerformance("Future", () async {
                                return await CalculatePrime.calculatePrimeNumF(
                                  5000000,
                                );
                              }),
                        ),
                        IsolateDemoCard(
                          title: "Compute Method",
                          subtitle: "Flutter's built-in helper",
                          buttonTitle: "Compute",
                          icon: Icons.bolt,
                          color: Colors.amber,
                          isLoading: _isLoading && _currentMethod == "Compute",
                          onClick:
                              () => _measurePerformance("Compute", () async {
                                return await compute(
                                  CalculatePrime.calculatePrimeNum,
                                  5000000,
                                );
                              }),
                        ),
                        IsolateDemoCard(
                          title: "Isolate.run",
                          subtitle: "Modern single-task isolate",
                          buttonTitle: "Isolate.run",
                          icon: Icons.memory,
                          color: Colors.green,
                          isLoading:
                              _isLoading && _currentMethod == "Isolate.run",
                          onClick:
                              () =>
                                  _measurePerformance("Isolate.run", () async {
                                    return await Isolate.run(
                                      () => CalculatePrime.calculatePrimeNum(
                                        5000000,
                                      ),
                                    );
                                  }),
                        ),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: IsolateDemoCard(
                        title: "Isolate.spawn",
                        subtitle: "Low-level port communication worker",
                        buttonTitle: "Spawn Custom Isolate Worker",
                        icon: Icons.layers,
                        color: Colors.deepPurpleAccent,
                        isLoading:
                            _isLoading && _currentMethod == "Isolate.spawn",
                        onClick:
                            () =>
                                _measurePerformance("Isolate.spawn", () async {
                                  final receivePort = ReceivePort();
                                  await Isolate.spawn(
                                    IsolateSpawnImpl.primeWorker,
                                    receivePort.sendPort,
                                  );
                                  final data = await receivePort.first;
                                  return data as List<int>;
                                }),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  _buildResultsSectionHeader(theme),
                  _buildResultsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "UI Thread Animator",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Test UI Responsiveness:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricsColumn(
                "Active Method",
                _isLoading ? _currentMethod : "Idle",
                _isLoading ? Colors.blue : Colors.grey,
              ),
              _buildMetricsColumn(
                "Execution Time",
                "${_executionTime.inMilliseconds} ms",
                Colors.green,
              ),
              _buildMetricsColumn(
                "Items Generated",
                _primeList.length.toString(),
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsColumn(String title, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSectionHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(Icons.analytics_outlined, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              "COMPUTED RESULTS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(
            child: Text(
              "Processing intensive mathematical operations...",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    if (_primeList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(
            child: Text(
              "No data computed yet. Tap an execution card above.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: Colors.blue[50],
                radius: 14,
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                "Prime Number Found: ${_primeList[index]}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          );
        }, childCount: _primeList.length > 100 ? 100 : _primeList.length),
      ),
    );
  }

  SliverChildListVisuals(List children) => children;
}
