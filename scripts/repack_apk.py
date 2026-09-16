import os
import zipfile
import subprocess
import shutil

def repack_apk():
    apk_source = 'public/downloads/altakhfeed-alsh.apk'
    backup_apk = '/tmp/original_altakhfeed.apk'
    unsigned_apk = '/tmp/unsigned.apk'
    aligned_apk = '/tmp/aligned.apk'
    output_apk = 'public/downloads/altakhfeed-alsh.apk'
    keystore = '/tmp/debug.keystore'

    if not os.path.exists(backup_apk):
        shutil.copyfile(apk_source, backup_apk)

    print(f"Reading base APK: {backup_apk}")
    
    # Read files to inject from dist
    dist_dir = 'dist'
    dist_files = {}
    for root, dirs, files in os.walk(dist_dir):
        for file in files:
            if file.endswith('.apk') or file.endswith('.bak'):
                continue
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, dist_dir)
            apk_path = 'assets/public/' + rel_path.replace('\\', '/')
            with open(full_path, 'rb') as f:
                dist_files[apk_path] = f.read()

    print(f"Prepared {len(dist_files)} assets from {dist_dir} to inject into APK")

    # Create unsigned zip
    if os.path.exists(unsigned_apk):
        os.remove(unsigned_apk)

    with zipfile.ZipFile(backup_apk, 'r') as src_zip:
        with zipfile.ZipFile(unsigned_apk, 'w', compression=zipfile.ZIP_DEFLATED) as dst_zip:
            existing_names = set(src_zip.namelist())
            for item in src_zip.infolist():
                name = item.filename
                # Skip signature files
                if name.startswith('META-INF/') and (
                    name.endswith('.SF') or name.endswith('.RSA') or 
                    name.endswith('.DSA') or name.endswith('.EC') or 
                    name == 'META-INF/MANIFEST.MF'
                ):
                    continue

                # If this is one of our dist assets, we will write our new version
                if name in dist_files:
                    continue

                # If it's an old asset in assets/public that's not in dist, skip it if stale js/css
                if name.startswith('assets/public/assets/') and (name.endswith('.js') or name.endswith('.css')):
                    continue

                data = src_zip.read(name)
                # Keep uncompressed if stored
                compress_type = item.compress_type
                dst_zip.writestr(item, data)

            # Write all new assets from dist
            for apk_path, data in dist_files.items():
                zinfo = zipfile.ZipInfo(filename=apk_path)
                zinfo.compress_type = zipfile.ZIP_DEFLATED
                # If image or mp3, keep STORED
                if apk_path.endswith(('.png', '.jpg', '.jpeg', '.webp', '.ico', '.svg')):
                    zinfo.compress_type = zipfile.ZIP_STORED
                dst_zip.writestr(zinfo, data)

    print("Created unsigned APK with fresh assets. Now running zipalign...")
    if os.path.exists(aligned_apk):
        os.remove(aligned_apk)

    subprocess.check_call(['zipalign', '-f', '-p', '4', unsigned_apk, aligned_apk])
    print("Zipalign complete. Now signing with apksigner...")

    subprocess.check_call([
        'apksigner', 'sign',
        '--ks', keystore,
        '--ks-pass', 'pass:android',
        '--key-pass', 'pass:android',
        '--ks-key-alias', 'androiddebugkey',
        '--v1-signing-enabled', 'true',
        '--v2-signing-enabled', 'true',
        '--out', output_apk,
        aligned_apk
    ])

    print("Signing complete. Verifying signature...")
    subprocess.check_call(['apksigner', 'verify', '-v', output_apk])
    print("SUCCESS: APK re-packaged and verified successfully!")

if __name__ == '__main__':
    repack_apk()
