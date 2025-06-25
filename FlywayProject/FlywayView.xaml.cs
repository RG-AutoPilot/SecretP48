using System;
using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;

namespace FlywayProject
{
    public partial class FlywayView : UserControl
    {
        public FlywayView()
        {
            InitializeComponent();
        }

        private void OnDeployClicked(object sender, RoutedEventArgs e)
        {
            string flywayDir = FlywayDirBox.Text.Trim();
            string source = FlywaySourceBox.Text.Trim();
            string target = FlywayTargetBox.Text.Trim();
            string additional = FlywayParamsBox.Text.Trim();

            if (string.IsNullOrWhiteSpace(flywayDir) || string.IsNullOrWhiteSpace(source) || string.IsNullOrWhiteSpace(target))
            {
                MessageBox.Show("Please fill in all required fields (Flyway Directory, Source, Target).", "Validation Error", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string command =
                $"prepare deploy " +
                $"-prepare.source={source} " +
                $"-prepare.target={target} " +
                $"-environment={target} " +
                $"-environments.{target}.user=REPLACE_ME " +
                $"-environments.{target}.password=REPLACE_ME " +
                $"-prepare.scriptFilename=\"{flywayDir}\\Artifact\\migration.sql\" " +
                $"-deploy.scriptFilename=\"{flywayDir}\\Artifact\\migration.sql\" " +
                "-prepare.force=true " +
                $"-configFiles=\"{flywayDir}\\flyway.toml\" " +
                $"-schemaModelLocation=\"{flywayDir}\\schema-model\" " +
                "-cleanDisabled=false " +
                additional;

            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = $"/k flyway {command}",
                    WorkingDirectory = flywayDir,
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to run Flyway:\n{ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}
