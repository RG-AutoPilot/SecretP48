using System.Windows;
using System.Windows.Controls;

namespace FlywayProject
{
    public partial class FlywayToolWindowControl : UserControl
    {
        private readonly FlywayView _flywayView = new FlywayView();
        private readonly TdmView _tdmView = new TdmView();

        public FlywayToolWindowControl()
        {
            InitializeComponent();
            MainContentArea.Content = _flywayView; // Default view
        }

        private void OnFlywayClick(object sender, RoutedEventArgs e)
        {
            MainContentArea.Content = _flywayView;
        }

        private void OnTdmClick(object sender, RoutedEventArgs e)
        {
            MainContentArea.Content = _tdmView;
        }
    }
}
