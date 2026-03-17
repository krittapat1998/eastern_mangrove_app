import 'package:flutter/material.dart';

class EcosystemServiceScreen extends StatefulWidget {
  const EcosystemServiceScreen({super.key});

  @override
  State<EcosystemServiceScreen> createState() => _EcosystemServiceScreenState();
}

class _EcosystemServiceScreenState extends State<EcosystemServiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Lists to store data
  final List<ResourceData> _resourcesData = [
    ResourceData(
      id: 'R001',
      resourceType: 'ปู',
      quantity: 25.5,
      unit: 'กิโลกรัม',
      pricePerUnit: 120.0,
      totalValue: 3060.0,
      date: DateTime(2024, 2, 25),
      location: 'บ้านปลา',
    ),
    ResourceData(
      id: 'R002', 
      resourceType: 'กุ้ง',
      quantity: 15.0,
      unit: 'กิโลกรัม',
      pricePerUnit: 280.0,
      totalValue: 4200.0,
      date: DateTime(2024, 2, 28),
      location: 'ธนาคารปู',
    ),
  ];

  final List<ActivityData> _activitiesData = [
    ActivityData(
      id: 'A001',
      activityType: 'การนำเที่ยว',
      numberOfPeople: 25,
      pricePerPerson: 150.0,
      totalIncome: 3750.0,
      date: DateTime(2024, 2, 20),
      description: 'นำเที่ยวชมป่าชายเลนและเรียนรู้วิถีชุมชน',
    ),
    ActivityData(
      id: 'A002',
      activityType: 'การรับกลุ่มสัมมนา',
      numberOfPeople: 40,
      pricePerPerson: 200.0,
      totalIncome: 8000.0,
      date: DateTime(2024, 2, 22),
      description: 'สัมมนาการอนุรักษ์ป่าชายเลนสำหรับนักเรียน',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('บริการทางนิเวศของป่าชายเลน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF4CAF50),
          tabs: const [
            Tab(text: 'บันทึกทรัพยากร', icon: Icon(Icons.nature)),
            Tab(text: 'บันทึกกิจกรรม', icon: Icon(Icons.group)),
            Tab(text: 'รายงาน', icon: Icon(Icons.assessment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResourceTab(),
          _buildActivityTab(), 
          _buildReportTab(),
        ],
      ),
    );
  }

  Widget _buildResourceTab() {
    return Column(
      children: [
        // Summary Cards
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'รายได้จากทรัพยากร',
                  '${_getTotalResourceValue().toStringAsFixed(0)} บาท',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'รายการทั้งหมด',
                  '${_resourcesData.length} รายการ',
                  Icons.nature,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ),
        
        // Add Resource Button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddResourceDialog(),
              icon: const Icon(Icons.add),
              label: const Text('บันทึกทรัพยากรใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        
        const Divider(height: 1),
        
        // Resources List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _resourcesData.length,
            itemBuilder: (context, index) {
              final resource = _resourcesData[index];
              return _buildResourceCard(resource, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    return Column(
      children: [
        // Summary Cards
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'รายได้จากกิจกรรม',
                  '${_getTotalActivityIncome().toStringAsFixed(0)} บาท',
                  Icons.monetization_on,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'จำนวนผู้เข้าร่วม',
                  '${_getTotalParticipants()} คน',
                  Icons.group,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),
        
        // Add Activity Button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddActivityDialog(),
              icon: const Icon(Icons.add),
              label: const Text('บันทึกกิจกรรมใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        
        const Divider(height: 1),
        
        // Activities List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _activitiesData.length,
            itemBuilder: (context, index) {
              final activity = _activitiesData[index];
              return _buildActivityCard(activity, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportTab() {
    final totalResourceValue = _getTotalResourceValue();
    final totalActivityIncome = _getTotalActivityIncome();
    final totalIncome = totalResourceValue + totalActivityIncome;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Income Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'รายได้รวมจากบริการนิเวศ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${totalIncome.toStringAsFixed(0)} บาท',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เดือน ${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Income Breakdown
          Row(
            children: [
              Expanded(
                child: _buildIncomeCard(
                  'จากทรัพยากร',
                  totalResourceValue,
                  totalIncome > 0 ? (totalResourceValue / totalIncome * 100) : 0,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIncomeCard(
                  'จากกิจกรรม',
                  totalActivityIncome,
                  totalIncome > 0 ? (totalActivityIncome / totalIncome * 100) : 0,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Resource Types Breakdown
          _buildSectionCard(
            'ประเภททรัพยากรที่เก็บใช้',
            Icons.nature,
            Colors.green,
            _buildResourceTypesList(),
          ),

          const SizedBox(height: 20),

          // Activity Types Breakdown  
          _buildSectionCard(
            'ประเภทกิจกรรมที่สร้างรายได้',
            Icons.group,
            Colors.orange,
            _buildActivityTypesList(),
          ),

          const SizedBox(height: 20),

          // Monthly Trend (Mock Data)
          _buildSectionCard(
            'แนวโน้มรายได้รายเดือน',
            Icons.trending_up,
            Colors.blue,
            _buildMonthlyTrend(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(ResourceData resource, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getResourceIcon(resource.resourceType),
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.resourceType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${resource.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${resource.totalValue.toStringAsFixed(0)} บาท',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('แก้ไข'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('ลบ'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditResourceDialog(resource, index);
                    } else if (value == 'delete') {
                      _deleteResource(index);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'ปริมาณ:',
                    '${resource.quantity} ${resource.unit}',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'ราคา/หน่วย:',
                    '${resource.pricePerUnit.toStringAsFixed(0)} บาท',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'สถานที่:',
                    resource.location,
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'วันที่:',
                    '${resource.date.day}/${resource.date.month}/${resource.date.year}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityData activity, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getActivityIcon(activity.activityType),
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.activityType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${activity.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${activity.totalIncome.toStringAsFixed(0)} บาท',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('แก้ไข'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('ลบ'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditActivityDialog(activity, index);
                    } else if (value == 'delete') {
                      _deleteActivity(index);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'จำนวนคน:',
                    '${activity.numberOfPeople} คน',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'ราคา/คน:',
                    '${activity.pricePerPerson.toStringAsFixed(0)} บาท',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildInfoRow(
              'วันที่:',
              '${activity.date.day}/${activity.date.month}/${activity.date.year}',
            ),

            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(String title, double amount, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${amount.toStringAsFixed(0)} บาท',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildResourceTypesList() {
    final resourceTypes = <String, double>{};
    for (final resource in _resourcesData) {
      resourceTypes[resource.resourceType] = 
          (resourceTypes[resource.resourceType] ?? 0) + resource.totalValue;
    }

    return Column(
      children: resourceTypes.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                _getResourceIcon(entry.key),
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(entry.key)),
              Text(
                '${entry.value.toStringAsFixed(0)} บาท',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityTypesList() {
    final activityTypes = <String, double>{};
    for (final activity in _activitiesData) {
      activityTypes[activity.activityType] = 
          (activityTypes[activity.activityType] ?? 0) + activity.totalIncome;
    }

    return Column(
      children: activityTypes.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                _getActivityIcon(entry.key),
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(entry.key)),
              Text(
                '${entry.value.toStringAsFixed(0)} บาท',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyTrend() {
    // Mock monthly data
    final months = ['ม.ค.', 'ก.พ.', 'มี.ค.'];
    final values = [12500.0, 15800.0, _getTotalResourceValue() + _getTotalActivityIncome()];

    return Column(
      children: [
        for (int i = 0; i < months.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    months[i],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: values[i] / 20000, // Scale for display
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${values[i].toStringAsFixed(0)} บ.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getResourceIcon(String resourceType) {
    switch (resourceType.toLowerCase()) {
      case 'ปู':
        return Icons.water;
      case 'กุ้ง':
        return Icons.water_drop;
      case 'หอย':
        return Icons.circle;
      case 'ไม้ฟืน':
        return Icons.nature;
      case 'ปลา':
        return Icons.waves;
      default:
        return Icons.eco;
    }
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'การนำเที่ยว':
        return Icons.tour;
      case 'การรับกลุ่มสัมมนา':
        return Icons.group;
      case 'การฝึกอบรม':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  double _getTotalResourceValue() {
    return _resourcesData.fold(0, (sum, resource) => sum + resource.totalValue);
  }

  double _getTotalActivityIncome() {
    return _activitiesData.fold(0, (sum, activity) => sum + activity.totalIncome);
  }

  int _getTotalParticipants() {
    return _activitiesData.fold(0, (sum, activity) => sum + activity.numberOfPeople);
  }

  void _showAddResourceDialog() {
    _showResourceDialog();
  }

  void _showEditResourceDialog(ResourceData resource, int index) {
    _showResourceDialog(resource: resource, index: index);
  }

  void _showResourceDialog({ResourceData? resource, int? index}) {
    final formKey = GlobalKey<FormState>();
    final resourceTypeController = TextEditingController(text: resource?.resourceType ?? '');
    final quantityController = TextEditingController(text: resource?.quantity.toString() ?? '');
    final unitController = TextEditingController(text: resource?.unit ?? 'กิโลกรัม');
    final priceController = TextEditingController(text: resource?.pricePerUnit.toString() ?? '');
    final locationController = TextEditingController(text: resource?.location ?? '');
    DateTime selectedDate = resource?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource == null ? 'บันทึกทรัพยากรใหม่' : 'แก้ไขข้อมูลทรัพยากร',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Resource Type
                DropdownButtonFormField<String>(
                  value: resourceTypeController.text.isNotEmpty ? resourceTypeController.text : null,
                  decoration: const InputDecoration(
                    labelText: 'ประเภททรัพยากร *',
                    border: OutlineInputBorder(),
                  ),
                  items: ['ปู', 'กุ้ง', 'หอย', 'ปลา', 'ไม้ฟืน', 'อื่นๆ']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => resourceTypeController.text = value!,
                  validator: (value) => value == null ? 'กรุณาเลือกประเภททรัพยากร' : null,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ปริมาณ *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'กรุณาป้อนปริมาณ';
                          if (double.tryParse(value) == null) return 'กรุณาป้อนตัวเลข';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'หน่วย',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ราคาต่อหน่วย (บาท) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณาป้อนราคา';
                    if (double.tryParse(value) == null) return 'กรุณาป้อนตัวเลข';
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'สถานที่เก็บ',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final quantity = double.parse(quantityController.text);
                          final price = double.parse(priceController.text);
                          final newResource = ResourceData(
                            id: resource?.id ?? 'R${DateTime.now().millisecondsSinceEpoch}',
                            resourceType: resourceTypeController.text,
                            quantity: quantity,
                            unit: unitController.text,
                            pricePerUnit: price,
                            totalValue: quantity * price,
                            date: selectedDate,
                            location: locationController.text,
                          );

                          setState(() {
                            if (index != null) {
                              _resourcesData[index] = newResource;
                            } else {
                              _resourcesData.add(newResource);
                            }
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(resource == null 
                                ? 'บันทึกข้อมูลทรัพยากรสำเร็จ' 
                                : 'แก้ไขข้อมูลทรัพยากรสำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(resource == null ? 'บันทึก' : 'แก้ไข'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddActivityDialog() {
    _showActivityDialog();
  }

  void _showEditActivityDialog(ActivityData activity, int index) {
    _showActivityDialog(activity: activity, index: index);
  }

  void _showActivityDialog({ActivityData? activity, int? index}) {
    final formKey = GlobalKey<FormState>();
    final activityTypeController = TextEditingController(text: activity?.activityType ?? '');
    final numberOfPeopleController = TextEditingController(text: activity?.numberOfPeople.toString() ?? '');
    final pricePerPersonController = TextEditingController(text: activity?.pricePerPerson.toString() ?? '');
    final descriptionController = TextEditingController(text: activity?.description ?? '');
    DateTime selectedDate = activity?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity == null ? 'บันทึกกิจกรรมใหม่' : 'แก้ไขข้อมูลกิจกรรม',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Activity Type
                DropdownButtonFormField<String>(
                  value: activityTypeController.text.isNotEmpty ? activityTypeController.text : null,
                  decoration: const InputDecoration(
                    labelText: 'ประเภทกิจกรรม *',
                    border: OutlineInputBorder(),
                  ),
                  items: ['การนำเที่ยว', 'การรับกลุ่มสัมมนา', 'การฝึกอบรม', 'อื่นๆ']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => activityTypeController.text = value!,
                  validator: (value) => value == null ? 'กรุณาเลือกประเภทกิจกรรม' : null,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: numberOfPeopleController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'จำนวนคน *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'กรุณาป้อนจำนวนคน';
                          if (int.tryParse(value) == null) return 'กรุณาป้อนตัวเลข';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: pricePerPersonController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ค่าใช้จ่ายต่อคน (บาท) *', 
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'กรุณาป้อนค่าใช้จ่าย';
                          if (double.tryParse(value) == null) return 'กรุณาป้อนตัวเลข';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดกิจกรรม',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final numberOfPeople = int.parse(numberOfPeopleController.text);
                          final pricePerPerson = double.parse(pricePerPersonController.text);
                          final newActivity = ActivityData(
                            id: activity?.id ?? 'A${DateTime.now().millisecondsSinceEpoch}',
                            activityType: activityTypeController.text,
                            numberOfPeople: numberOfPeople,
                            pricePerPerson: pricePerPerson,
                            totalIncome: numberOfPeople * pricePerPerson,
                            date: selectedDate,
                            description: descriptionController.text,
                          );

                          setState(() {
                            if (index != null) {
                              _activitiesData[index] = newActivity;
                            } else {
                              _activitiesData.add(newActivity);
                            }
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(activity == null 
                                ? 'บันทึกข้อมูลกิจกรรมสำเร็จ' 
                                : 'แก้ไขข้อมูลกิจกรรมสำเร็จ'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(activity == null ? 'บันทึก' : 'แก้ไข'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteResource(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบข้อมูลทรัพยากรนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _resourcesData.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ลบข้อมูลทรัพยากรแล้ว'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteActivity(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบข้อมูลกิจกรรมนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _activitiesData.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ลบข้อมูลกิจกรรมแล้ว'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data Models
class ResourceData {
  final String id;
  final String resourceType;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double totalValue;
  final DateTime date;
  final String location;

  ResourceData({
    required this.id,
    required this.resourceType,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalValue,
    required this.date,
    required this.location,
  });
}

class ActivityData {
  final String id;
  final String activityType;
  final int numberOfPeople;
  final double pricePerPerson;
  final double totalIncome;
  final DateTime date;
  final String description;

  ActivityData({
    required this.id,
    required this.activityType,
    required this.numberOfPeople,
    required this.pricePerPerson,
    required this.totalIncome,
    required this.date,
    required this.description,
  });
}