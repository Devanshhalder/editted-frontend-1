import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UdyamHelpScreen extends StatefulWidget {
  const UdyamHelpScreen({super.key});

  @override
  State<UdyamHelpScreen> createState() => _UdyamHelpScreenState();
}

class _UdyamHelpScreenState extends State<UdyamHelpScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I add a product?',
      'answer':
      'Open the Catalog section and select Add Product. Enter your product name, category, description, price and other required details. Then save the product to add it to your catalog.',
    },
    {
      'question': 'How do I edit my product?',
      'answer':
      'Go to Catalog and select the product you want to modify. Open the product details and choose the edit option. Update the required information and save your changes.',
    },
    {
      'question': 'How do I publish my product?',
      'answer':
      'After adding a product, open its details and select the Publish option. Review your product information before publishing it to your selected marketplace or storefront.',
    },
    {
      'question': 'How do I complete my KYC?',
      'answer':
      'Open your Profile and go to your KYC section. Provide the required identity and business information and upload the requested documents. Follow the instructions shown in the app to complete verification.',
    },
    {
      'question': 'What is the Authentication Certificate?',
      'answer':
      'The Authentication Certificate helps establish your artisan identity and provides verification information associated with your KarigarKart profile.',
    },
    {
      'question': 'How does the Pricing Assistant work?',
      'answer':
      'The Pricing Assistant helps you understand and estimate suitable pricing for your products. Enter the relevant product information and review the suggested pricing information.',
    },
    {
      'question': 'How can I use AI Sahayak?',
      'answer':
      'AI Sahayak is designed to help you with common business and product-related questions. Open the AI Sahayak section and type your question to receive assistance.',
    },
    {
      'question': 'How do I update my profile?',
      'answer':
      'Open Profile and select Edit Profile. Update your personal, artisan or storefront information and save the changes.',
    },
    {
      'question': 'How do I change the app language?',
      'answer':
      'Open Profile, select Language and choose your preferred language from the available options.',
    },
    {
      'question': 'How do I manage my catalog?',
      'answer':
      'Open the Catalog section from the bottom navigation bar. From there you can view your products, add new products and manage existing product information.',
    },
    {
      'question': 'What should I do if my product is not publishing?',
      'answer':
      'First check that all required product information is complete. Also check your internet connection and marketplace connection. If the problem continues, contact Customer Support.',
    },
    {
      'question': 'What should I do if I have a technical problem?',
      'answer':
      'Try restarting the app and checking your internet connection. If the problem continues, contact KarigarKart Customer Support and provide details about the issue.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.trim().isEmpty) {
      return _faqs;
    }

    final query = _searchQuery.toLowerCase().trim();

    return _faqs.where((faq) {
      final question = faq['question']!.toLowerCase();
      final answer = faq['answer']!.toLowerCase();

      return question.contains(query) || answer.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _callCustomerCare() async {
    const phoneNumber = '+911800000000';

    final uri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showContactDialog(
          title: 'Customer Care',
          value: phoneNumber,
        );
      }
    } catch (_) {
      _showContactDialog(
        title: 'Customer Care',
        value: phoneNumber,
      );
    }
  }

  Future<void> _emailSupport() async {
    const email = 'support@karigarkart.com';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'KarigarKart Support Request',
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showContactDialog(
          title: 'Email Support',
          value: email,
        );
      }
    } catch (_) {
      _showContactDialog(
        title: 'Email Support',
        value: email,
      );
    }
  }

  void _showContactDialog({
    required String title,
    required String value,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SelectableText(value),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));

                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                  ),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final faqList = _filteredFaqs;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F3),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF292522),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Color(0xFF292522),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildHeader(),

            const SizedBox(height: 20),

            _buildSearchBar(),

            const SizedBox(height: 28),

            const Text(
              'Popular Help',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF292522),
              ),
            ),

            const SizedBox(height: 12),

            if (faqList.isEmpty)
              _buildNoResults()
            else
              ...faqList.map(
                    (faq) => _buildFaqTile(
                  question: faq['question']!,
                  answer: faq['answer']!,
                ),
              ),

            const SizedBox(height: 28),

            _buildSupportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3E806F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Find answers to common KarigarKart questions.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search your problem...',
        hintStyle: const TextStyle(
          color: Color(0xFF8A817A),
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF3E806F),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE4DCD4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE4DCD4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFF3E806F),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE4DCD4),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          iconColor: const Color(0xFF3E806F),
          collapsedIconColor: const Color(0xFF655D57),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF292522),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF655D57),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE4DCD4),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off,
            size: 42,
            color: Color(0xFF3E806F),
          ),
          SizedBox(height: 12),
          Text(
            'No help article found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try searching with a different keyword or contact Customer Support.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF655D57),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Still need help?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF292522),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Our support team can help you with problems that are not covered above.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF655D57),
            height: 1.4,
          ),
        ),

        const SizedBox(height: 14),

        _buildSupportCard(
          icon: Icons.headset_mic_outlined,
          title: 'Customer Care',
          subtitle: 'Talk to our support team',
          onTap: _callCustomerCare,
        ),

        const SizedBox(height: 10),

        _buildSupportCard(
          icon: Icons.email_outlined,
          title: 'Email Support',
          subtitle: 'Send us your complaint or issue',
          onTap: _emailSupport,
        ),
      ],
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE4DCD4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2EF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3E806F),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF292522),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF756C65),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Color(0xFF655D57),
              ),
            ],
          ),
        ),
      ),
    );
  }
}