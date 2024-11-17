import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';

class VehicalMakePage extends StatefulWidget {
  const VehicalMakePage(
      {Key? key, required this.onSelect, required this.selectedVehical})
      : super(key: key);

  final String selectedVehical;
  final Function onSelect;

  @override
  State<VehicalMakePage> createState() => _VehicalMakePageState();
}

class _VehicalMakePageState extends State<VehicalMakePage> {
  List<String> vehicalMake = ['Honda', 'GMC', 'Ford', 'Kia', 'Leusx', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // ignore: unnecessary_const
        const Text(
          'What make of vehicle is it ?',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
        ),

        const SizedBox(
          height: 10,
        ),

        Expanded(
          child: ListView.builder(
              itemBuilder: (ctx, i) {
                return ListTile(
                  onTap: () => widget.onSelect(vehicalMake[i]),
                  visualDensity: const VisualDensity(vertical: -4),
                  title: Text(vehicalMake[i]),
                  trailing: widget.selectedVehical == vehicalMake[i]
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: AppColors.purpleColor,
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
              itemCount: vehicalMake.length),
        ),
      ],
    );
  }
}
