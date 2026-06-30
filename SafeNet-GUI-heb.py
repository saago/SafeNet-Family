import sys
import subprocess
import threading
import os

# Suppress the specific CustomTkinter font warning robustly
class FilterOutput:
    def __init__(self, original_stream):
        self.original_stream = original_stream

    def write(self, message):
        if "Preferred drawing method 'font_shapes' can not be used" in message or "Using 'circle_shapes' instead" in message:
            return
        self.original_stream.write(message)

    def flush(self):
        self.original_stream.flush()

sys.stderr = FilterOutput(sys.stderr)
sys.stdout = FilterOutput(sys.stdout)

import customtkinter as ctk

# Set appearance mode and color theme
ctk.set_appearance_mode("System")
ctk.set_default_color_theme("blue")

# Force the drawing method to avoid the font loading warning on Windows
ctk.DrawEngine.preferred_drawing_method = "polygon_shapes"

class SafeNetApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("SafeNet-Family GUI")
        self.geometry("550x650")
        self.resizable(False, False)
        
        # Setting the font family for Hebrew support
        self.font_title = ctk.CTkFont(family="Arial", size=26, weight="bold")
        self.font_subtitle = ctk.CTkFont(family="Arial", size=16)
        self.font_bold = ctk.CTkFont(family="Arial", size=15, weight="bold")
        self.font_normal = ctk.CTkFont(family="Arial", size=14)
        self.font_console = ctk.CTkFont(family="Consolas", size=13)

        self.main_frame = ctk.CTkFrame(self, corner_radius=20)
        self.main_frame.pack(pady=20, padx=20, fill="both", expand=True)

        self.title_label = ctk.CTkLabel(self.main_frame, text="🛡️ SafeNet-Family", font=self.font_title)
        self.title_label.pack(pady=(20, 5))
        
        self.subtitle_label = ctk.CTkLabel(self.main_frame, text="מערכת סינון תכנים חכמה למשפחה", font=self.font_subtitle)
        self.subtitle_label.pack(pady=(0, 20))

        # YouTube Mode Selection
        self.yt_frame = ctk.CTkFrame(self.main_frame, corner_radius=10)
        self.yt_frame.pack(pady=10, padx=20, fill="x")
        
        self.yt_label = ctk.CTkLabel(self.yt_frame, text="סוג הקשחה ליוטיוב:", font=self.font_bold)
        self.yt_label.pack(anchor="e", padx=15, pady=(10, 5))

        self.yt_var = ctk.StringVar(value="מחמיר (Strict)")
        
        self.yt_segmented = ctk.CTkSegmentedButton(
            self.yt_frame, values=["מחמיר (Strict)", "מתון (Moderate)"], 
            variable=self.yt_var, font=self.font_normal,
            selected_color="#0052cc", selected_hover_color="#003d99"
        )
        self.yt_segmented.pack(pady=(5, 15), padx=15, fill="x")

        # Buttons
        self.buttons_frame = ctk.CTkFrame(self.main_frame, fg_color="transparent")
        self.buttons_frame.pack(pady=15, fill="x")

        self.install_btn = ctk.CTkButton(
            self.buttons_frame, text="התקנה / עדכון", font=self.font_bold, 
            fg_color="#28a745", hover_color="#218838", command=self.run_install
        )
        self.install_btn.pack(pady=8, fill="x", padx=20)

        self.status_btn = ctk.CTkButton(
            self.buttons_frame, text="בדיקת מצב", font=self.font_bold, 
            fg_color="#17a2b8", hover_color="#138496", command=self.run_status
        )
        self.status_btn.pack(pady=8, fill="x", padx=20)

        self.uninstall_btn = ctk.CTkButton(
            self.buttons_frame, text="הסרה (ביטול סינון)", font=self.font_bold, 
            fg_color="#dc3545", hover_color="#c82333", command=self.run_uninstall
        )
        self.uninstall_btn.pack(pady=8, fill="x", padx=20)

        # Output Textbox
        self.output_box = ctk.CTkTextbox(self.main_frame, height=140, font=self.font_console)
        self.output_box.pack(pady=(10, 10), padx=20, fill="both", expand=True)
        self.output_box.insert("0.0", "ממתין לפעולה...\n")
        self.output_box.configure(state="disabled")

        # Credit Label
        self.credit_label = ctk.CTkLabel(self.main_frame, text="Created by Netanel Elhadad", font=ctk.CTkFont(family="Arial", size=11, slant="italic"), text_color="gray")
        self.credit_label.pack(pady=(0, 10))

    def log(self, text):
        self.output_box.configure(state="normal")
        self.output_box.insert("end", text + "\n")
        self.output_box.see("end")
        self.output_box.configure(state="disabled")

    def clear_log(self):
        self.output_box.configure(state="normal")
        self.output_box.delete("0.0", "end")
        self.output_box.configure(state="disabled")

    def run_command(self, script_name, args=[], requires_admin=False):
        self.clear_log()
        self.log(f"מריץ {script_name}...")

        if requires_admin:
            self.log("\nשים לב: חלון שורת פקודה נפרד ייפתח ויבקש הרשאות מנהל.")
            self.log("אנא אשר את הבקשה (Yes) ופעל לפי ההוראות בחלון שייפתח.")

        script_dir = os.path.dirname(os.path.abspath(__file__))
        script_path = os.path.join(script_dir, script_name)
        
        if not os.path.exists(script_path):
            self.log(f"שגיאה: הקובץ {script_name} לא נמצא.")
            return

        cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", script_path] + args

        def run():
            try:
                process = subprocess.Popen(
                    cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, 
                    text=True, creationflags=subprocess.CREATE_NO_WINDOW
                )
                stdout, stderr = process.communicate()
                
                self.output_box.configure(state="normal")
                if stdout.strip():
                    self.output_box.insert("end", "\n" + stdout.strip() + "\n")
                if stderr.strip():
                    self.output_box.insert("end", "\nשגיאות:\n" + stderr.strip() + "\n")
                
                self.output_box.insert("end", "\n--- הפעולה הושלמה ---\n")
                self.output_box.see("end")
                self.output_box.configure(state="disabled")
            except Exception as e:
                self.log(f"\nשגיאה בהרצה: {str(e)}")

        threading.Thread(target=run, daemon=True).start()

    def run_install(self):
        yt_mode_str = self.yt_var.get()
        yt_mode = "Moderate" if "Moderate" in yt_mode_str else "Strict"
        self.run_command("Install.ps1", ["-YouTubeMode", yt_mode], requires_admin=True)

    def run_status(self):
        self.run_command("Status.ps1")

    def run_uninstall(self):
        self.run_command("Uninstall.ps1", requires_admin=True)

if __name__ == "__main__":
    app = SafeNetApp()
    app.mainloop()
