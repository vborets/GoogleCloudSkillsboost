```

# Import required libraries
from google import genai
from google.genai.types import (
    Image,
    EditImageConfig,
    RawReferenceImage,
    MaskReferenceImage,
    MaskReferenceConfig,
)
import image_editing_utils

# Initialize the Google Gen AI SDK
PROJECT_ID = "[Your Project ID]"  # Replace with your actual Project ID
LOCATION = "us-central1"  # Or your preferred region
gcs_bucket = f"{PROJECT_ID}-bucket"  # GCS Bucket Name

client = genai.Client(
    vertexai=True,
    project=PROJECT_ID,
    location=LOCATION
)

# Task 1: Prepare the environment
# Download the starting images
!gcloud storage cp gs://{PROJECT_ID}-bucket/empty-bowl-on-empty-table.png .
!gcloud storage cp gs://{PROJECT_ID}-bucket/image_editing_utils.py .
!gcloud storage cp gs://{PROJECT_ID}-bucket/place-setting-mask.png .

# Display the original image
original_image = Image.from_file(
    location="empty-bowl-on-empty-table.png",
    mime_type="image/png"
)
original_image.show()

# Save and upload original image
dest_filename = "empty-bowl-on-empty-table-copy.png"
original_image.save(dest_filename)
image_editing_utils.upload_file_to_gcs(
    gcs_bucket, dest_filename, dest_filename)

# Task 2: Use outpainting to expand the image's aspect ratio
edit_model_name = "imagen-3.0-capability-001"

target_image_size = (1408, 768)
reframed_image, reframed_mask = image_editing_utils.pad_and_mask_image(
    original_image=original_image,
    target_size=target_image_size,
    vertical_offset_from_bottom=0.5,
    horizontal_offset_from_left=0.1,
)

reframed_image.show()
reframed_mask.show()

raw_ref_image = RawReferenceImage(
    reference_image=reframed_image,
    reference_id=0
)

mask_ref_image = MaskReferenceImage(
    reference_id=1,
    reference_image=reframed_mask,
    config=MaskReferenceConfig(
        mask_mode="MASK_MODE_USER_PROVIDED",
        mask_dilation=0.1,
    )
)

outpainted_image = client.models.edit_image(
    model=edit_model_name,
    prompt="",
    reference_images=[raw_ref_image, mask_ref_image],
    config=EditImageConfig(
        edit_mode="EDIT_MODE_OUTPAINT",
        number_of_images=1,
        base_steps=35,
        safety_filter_level="BLOCK_ONLY_HIGH",
    ),
)

outpainted_image.generated_images[0].image.show()

filename = "empty-bowl-on-long-table.png"
outpainted_image.generated_images[0].image.save(filename)
image_editing_utils.upload_file_to_gcs(gcs_bucket, filename, filename)

# Task 3: Use mask-free editing to add grapes
raw_ref_image = RawReferenceImage(
    reference_image=outpainted_image.generated_images[0].image,
    reference_id=0
)

edit_prompt = "photoreal wet grapes added to the ceramic bowl[0]."
edited_image = client.models.edit_image(
    model=edit_model_name,
    prompt=edit_prompt,
    reference_images=[raw_ref_image],
    config=EditImageConfig(
        edit_mode="EDIT_MODE_DEFAULT",
        base_steps=35,
        number_of_images=1,
        safety_filter_level="BLOCK_MEDIUM_AND_ABOVE",
    ),
)

edited_image.generated_images[0].image.show()

filename = "grapes-in-bowl-on-long-table.png"
edited_image.generated_images[0].image.save(filename)
image_editing_utils.upload_file_to_gcs(gcs_bucket, filename, filename)

# Task 4: Use inpainting to insert objects into the scene
raw_ref_image = RawReferenceImage(
    reference_image=edited_image.generated_images[0].image,
    reference_id=0
)

place_setting_mask = Image.from_file(location="place-setting-mask.png")
mask_ref_image = MaskReferenceImage(
    reference_id=1,
    reference_image=place_setting_mask,
    config=MaskReferenceConfig(
        mask_mode="MASK_MODE_USER_PROVIDED",
        mask_dilation=0.1,
    )
)

edit_prompt = "a fork on a napkin and a plate on the rustic table[1]"
inpainted_image = client.models.edit_image(
    model=edit_model_name,
    prompt=edit_prompt,
    reference_images=[raw_ref_image, mask_ref_image],
    config=EditImageConfig(
        edit_mode="EDIT_MODE_INPAINT_INSERTION",
        number_of_images=1,
        safety_filter_level="BLOCK_MEDIUM_AND_ABOVE",
    ),
)

inpainted_image.generated_images[0].image.show()

filename = "grapes-and-table-setting-on-long-table.png"
inpainted_image.generated_images[0].image.save(filename)
image_editing_utils.upload_file_to_gcs(gcs_bucket, filename, filename)

# Task 5: Clear the table with inpainting removal
raw_ref_image = RawReferenceImage(
    reference_image=inpainted_image.generated_images[0].image,
    reference_id=0
)

mask_ref_image = MaskReferenceImage(
    reference_id=1,
    reference_image=None,
    config=MaskReferenceConfig(
        mask_mode="MASK_MODE_FOREGROUND",
        mask_dilation=0.1,
    )
)

edit_prompt = ""
foreground_removed_image = client.models.edit_image(
    model=edit_model_name,
    prompt=edit_prompt,
    reference_images=[raw_ref_image, mask_ref_image],
    config=EditImageConfig(
        edit_mode="EDIT_MODE_INPAINT_REMOVAL",
        number_of_images=1,
        safety_filter_level="BLOCK_MEDIUM_AND_ABOVE",
    ),
)

foreground_removed_image.generated_images[0].image.show()

filename = "empty-table.png"
foreground_removed_image.generated_images[0].image.save(filename)
image_editing_utils.upload_file_to_gcs(gcs_bucket, filename, filename)

# Task 6: Create neutral background
raw_ref_image = RawReferenceImage(
    reference_image=original_image,
    reference_id=0
)

mask_ref_image = MaskReferenceImage(
    reference_id=1,
    reference_image=None,
    config=MaskReferenceConfig(
        mask_mode="MASK_MODE_SEMANTIC",
        segmentation_classes=[67],  # Class ID for table
        mask_dilation=0.1,
    )
)

edit_prompt = ""
neutral_surface_image = client.models.edit_image(
    model=edit_model_name,
    prompt=edit_prompt,
    reference_images=[raw_ref_image, mask_ref_image],
    config=EditImageConfig(
        edit_mode="EDIT_MODE_INPAINT_REMOVAL",
        number_of_images=1,
        safety_filter_level="BLOCK_MEDIUM_AND_ABOVE",
    ),
)

neutral_surface_image.generated_images[0].image.show()

filename = "bowl-on-neutral-surface.png"
neutral_surface_image.generated_images[0].image.save(filename)
image_editing_utils.upload_file_to_gcs(gcs_bucket, filename, filename)

# Task 7: Swap the background to a festive party
raw_ref_image = RawReferenceImage(
    reference_image=original_image,
    reference_id=0
)

mask_ref_image = MaskReferenceImage(
    reference_id=1,
    reference_image=None,
    config=MaskReferenceConfig(
        mask_mode="MASK_MODE_BACKGROUND",
        mask_dilation=0.1,
    )
)

edit_prompt = "A bowl on a table at a fun dinner party"
dinner_party_image = client.models.edit_image(
    model=edit_model_name,
    prompt=edit_prompt,
    reference_images=[raw_ref_image, mask_ref_image],
    config=EditImageConfig(
        edit_mode="EDIT_MODE_INPAINT_INSERTION",
        number_of_images=1,
        safety_filter_level="BLOCK_MEDIUM_AND_ABOVE",
    ),
)

dinner_party_image.generated_images[0].image.show()

filename = "bowl-at-a-party.png"
dinner_party_image.generated_images[0].image.save(filename)
image_editing_utils.upload_file_to_gcs(gcs_bucket, filename, filename)

```
