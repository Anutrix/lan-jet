using System;
using System.Text;
using System.Runtime.InteropServices;

namespace Anutrix
{
    public class WindowsUser
    {
        enum GetUserPictureFlags : uint
        {
            Directory = 0x1,
            DefaultDirectory = 0x2,
            CreatePicturesDir = 0x80000000
        }

        [DllImport("shell32.dll", EntryPoint = "#261", CharSet = CharSet.Auto)]
        static extern void SHGetUserPicturePath(string name, GetUserPictureFlags flags, StringBuilder path, int pathLength);

        public static string GetUserPicturePath()
        {
            var pathBuffer = new StringBuilder(1024);
            SHGetUserPicturePath(null, GetUserPictureFlags.CreatePicturesDir, pathBuffer, pathBuffer.Capacity);
            return pathBuffer.ToString();
        }
    }
}